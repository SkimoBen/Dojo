from supermemory import Supermemory 
import os 
from pydantic import BaseModel
from typing import Union
from uuid import UUID
from dotenv import load_dotenv 
import json 
from completed_workouts_model import CompletedClimbingWorkoutDTO, CompletedRunningWorkoutDTO
from models import CoordinatorAgentContext


load_dotenv()

client = Supermemory(api_key=os.environ.get("SUPERMEMORY_API_KEY")) 

class WorkoutPayload(BaseModel):
    userId: UUID
    #allow one of the two workout types
    workout: Union[CompletedClimbingWorkoutDTO, CompletedRunningWorkoutDTO]  
    coordinatorContext: CoordinatorAgentContext

def save_workout_to_memory(workoutPayload: WorkoutPayload):
    client = Supermemory(api_key=os.environ.get("SUPERMEMORY_API_KEY"))
    workoutMemory = f"user_{workoutPayload.userId}: \n{workoutPayload.workout.model_dump(mode="python")}"

    result = client.memories.add(
        content = workoutMemory,
        container_tags = [
            f"{workoutPayload.workout.activity}"
        ],
        metadata= {
            "user": str(workoutPayload.userId),
            "date": str(workoutPayload.workout.date.year) + "-" + str(workoutPayload.workout.date.month) + "-" + str(workoutPayload.workout.date.day),
            "activity": workoutPayload.workout.activity
            }
    )
    print(result)

def search_workout_documents(userId: str, query: str, activity: str, limit: int = 5) -> str: 
    results = client.search.documents(
        q=query,
        limit=limit,
        document_threshold=0.4,
        chunk_threshold=0.4,
        rerank=True,
        rewrite_query=True,
        include_full_docs=True,
        include_summary=True,
        only_matching_chunks=False,
        container_tags=[activity],
        filters={
            "AND": [{"key" : "user", "value" : userId}]
        }
    )
    print("🔎📄 Searched documents and found ", len(results.results), " results.")
    return json.dumps(results.model_dump(), indent=2)

def search_workout_memories(userId: str, query: str, activity: str, limit: int = 5):

    filters = {
        "AND": [
            {"key": "user", "value": userId}
        ]
    }

    results = client.search.memories(
        q=query,
        container_tag=activity,
        limit=limit,
        threshold=0.5,
        rerank=True,
        filters= filters, 
    )
    print("🔎🧠 Searched memories and found ", len(results.results), " results.")
    return json.dumps(results.model_dump(), indent=2)