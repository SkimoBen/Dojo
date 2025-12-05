# fastapi_app.py
from typing import Any, Dict, List, cast, Union
from pydantic import BaseModel, model_validator
from uuid import UUID
from datetime import datetime
from fastapi import FastAPI
from agents import Runner, TResponseInputItem 
from models import CoordinatorAgentContext  # your model
from custom_agents import coordinator_chatbot_agent, climbing_coach, running_coach
from completed_workouts_model import CompletedClimbingWorkoutDTO, CompletedRunningWorkoutDTO
from memory_management import WorkoutPayload, save_workout_to_memory

app = FastAPI()
## TO RUN LOCALLY: uvicorn main:app --reload --host 0.0.0.0 --port 8000

class ChatPayload(BaseModel):
    # <-- Treat messages as plain JSON dicts; do NOT use TResponseInputItem here.
    messages: List[Dict[str, Any]]
    coordinatorContext: CoordinatorAgentContext
    timestamp: datetime
    userId: UUID
    conversation_id: str

 

@app.post("/chat")
async def chat(payload: ChatPayload):
    # It's so stupid that I have to do this it does nothing other than prevent the 
    # garbage type checker from complaining.
    input_items = cast(list[TResponseInputItem], payload.messages) 
    print("Payload reeived for ", payload.coordinatorContext.userId)
    result = await Runner.run(
        starting_agent=coordinator_chatbot_agent,
        input=input_items,
        context=payload.coordinatorContext
        #conversation_id=payload.conversation_id,
        # optionally:
        # previous_response_id=payload.previous_response_id,
        
    )
    print("Completed the result")
    # print("Updated Context:")
    # print(result.context_wrapper.context)

    # print("Context Wrapper")
    # print(result.context_wrapper)
    return {
        "server_msg": "no_update",
        "messages": result.to_input_list(),  # list[ResponseInputItemParam]-compatible dicts
        "context": result.context_wrapper.context,
    }



@app.post("/submit_workout")
async def submit_workout(payload: WorkoutPayload):
    print("Received workout submission:")

    messages = [
        {
        "content": f"Update my coach defined fitness level for {payload.workout.activity}, but first look at the workout I just submitted, and search memories for my workout history. My user ID is {payload.userId} Here is the workout:\n{payload.workout.model_dump(mode='python')}",
        "role": "user"
        }
    ]
    input_items = cast(list[TResponseInputItem], messages) 
    # print(payload)
    currentAgent = running_coach or climbing_coach

    if payload.workout.activity == "climbing":
        workout = cast(CompletedClimbingWorkoutDTO, payload.workout)
        print(f"Climbing workout on {workout.date} with {len(workout.routes)} routes.")
        currentAgent = climbing_coach

    elif payload.workout.activity == "running":
        workout = cast(CompletedRunningWorkoutDTO, payload.workout)
        print(f"Running workout on {workout.date} for {workout.distanceKm} km.")
        currentAgent = running_coach

    save_workout_to_memory(payload)

    result = await Runner.run(
        starting_agent=currentAgent,
        input=input_items,
        context=payload.coordinatorContext
    )

    return {
        "server_msg": "updated fitness level",
        "context": result.context_wrapper.context,
    }
        
    

    