from pydantic import BaseModel, Field, field_validator, RootModel
import json
from datetime import datetime, timezone, timedelta

from grades_model import GradeValueModel

APPLE_REF = datetime(2001, 1, 1, tzinfo=timezone.utc)

class CompletedClimbingRouteDTO(BaseModel):
    grade: str
    attempts: int
    send: bool
    style: str

class CompletedClimbingWorkoutDTO(BaseModel): 
    date: datetime
    activity: str = "climbing"
    userNotes: str
    routes: list[CompletedClimbingRouteDTO]

    @field_validator("date", mode="before")
    @classmethod
    def _coerce_date(cls, v):
            # 1) Apple-reference seconds (Swift JSONEncoder default)
            if isinstance(v, (int, float)):
                return APPLE_REF + timedelta(seconds=float(v))
            # 2) ISO-8601 string
            if isinstance(v, str):
                return datetime.fromisoformat(v.replace("Z", "+00:00"))
            # 3) Already a datetime
            return v

class CompletedRunningWorkoutDTO(BaseModel):
    date: datetime
    activity: str = "running"
    userNotes: str
    distanceKm: float
    avgHeartRate: float
    elevationGain: float
    avgPacePerKm: float

    @field_validator("date", mode="before")
    @classmethod
    def _coerce_date(cls, v):
        # 1) Apple-reference seconds (Swift JSONEncoder default)
        if isinstance(v, (int, float)):
            return APPLE_REF + timedelta(seconds=float(v))
        # 2) ISO-8601 string
        if isinstance(v, str):
            return datetime.fromisoformat(v.replace("Z", "+00:00"))
        # 3) Already a datetime
        return v
    
