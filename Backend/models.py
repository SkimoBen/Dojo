#models.py
from pydantic import BaseModel, field_validator
from uuid import UUID
from datetime import datetime, timezone, timedelta
from enum import Enum
from agents import TResponseInputItem
from typing import List, Optional, TypedDict, Any

from planned_workouts_model import DailyWorkoutDTO

APPLE_REF = datetime(2001, 1, 1, tzinfo=timezone.utc)

### REQUEST PAYLOADS

class ActivityTypeEnum(str, Enum):
    climbing = "climbing"
    running = "running"

class UserDefinedGoal(BaseModel):
    id: UUID
    goalActivity: ActivityTypeEnum
    title: str
    description: str
    goalDeadline: datetime
    isCompleted: bool
    # userDefinedFitnessLevel: str
    # userDefinedFitnessLevelUpdatedDate: Optional[datetime] = None

    # ---- add these two validators ----
    @field_validator("goalDeadline", mode="before")
    @classmethod
    def _coerce_goal_deadline(cls, v):
        if isinstance(v, (int, float)):
            return APPLE_REF + timedelta(seconds=float(v))
        if isinstance(v, str):
            return datetime.fromisoformat(v.replace("Z", "+00:00"))
        return v


### CONTEXT 

class FitnessLevel(BaseModel):
    activity: ActivityTypeEnum
    userDefinedFitnessLevel: Optional[str] = None
    userDefinedFitnessLevelUpdatedDate: Optional[datetime] = None
    agentDefinedFitnessLevel: Optional[str] = None
    agentFitnessLevelUpdatedDate: Optional[datetime] = None

    @field_validator(
        "userDefinedFitnessLevelUpdatedDate",
        "agentFitnessLevelUpdatedDate",
        mode="before",
    )
    @classmethod
    def _coerce_updated_date(cls, v):
        if v is None:
            return v
        if isinstance(v, (int, float)):
            return APPLE_REF + timedelta(seconds=float(v))
        if isinstance(v, str):
            return datetime.fromisoformat(v.replace("Z", "+00:00"))
        return v

### TOP LEVEL CONTEXT MODEL
class CoordinatorAgentContext(BaseModel):
    userId: str
    goals: List[UserDefinedGoal]
    currentTrainingPlan: List[DailyWorkoutDTO]
    activityFitnessLevels: List[FitnessLevel]
   

    @field_validator("userId", mode="after")
    @classmethod
    def lowercase_user_id(cls, v: str) -> str:
        return v.lower()





########### TESTINHG 

# class IngestPayload(BaseModel):
#     type: str
#     data: UserDefinedGoal

class ChatOutput(TypedDict):
    messages: list[dict[str, Any]]
    coordinatorContext: dict[str, Any]
    timestamp: str
    userId: str
    conversation_id: str

class ChatInput(BaseModel):
    messages: List[TResponseInputItem]
    coordinatorContext: CoordinatorAgentContext
    timestamp: datetime
    userId: UUID
    conversation_id: str

### ENDPOINT PAYLOADS
class ChatPayload(BaseModel):
    messages: List[TResponseInputItem]
    coordinatorContext: CoordinatorAgentContext
    timestamp: datetime
    userId: UUID
    conversation_id: str



    
