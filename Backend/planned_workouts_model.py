# planned_workouts_model.py

from __future__ import annotations

from typing import List, Literal, Union, Any, Dict, Annotated
from uuid import UUID, uuid4
from datetime import datetime, timezone, timedelta
from pydantic import BaseModel, Field, field_validator, RootModel
import json

from grades_model import GradeValueModel

APPLE_REF = datetime(2001, 1, 1, tzinfo=timezone.utc)

# ----------------------------
# Shared wire types
# ----------------------------

ActivityTypeEnum = Literal["climbing", "running"]


# ----------------------------
# Protocol-ish base for sessions
# ----------------------------

class WorkoutSessionDTO(BaseModel):
    """
    Mirrors the Swift protocol WorkoutSessionDTO:
      - var sessionDescription: String { get set }
      - var activity: ActivityTypeEnum { get }
    """
    sessionDescription: str
    activity: ActivityTypeEnum


# ----------------------------
# Leaf models (routes + concrete sessions)
# ----------------------------

class ClimbRouteDTO(BaseModel):
    """
    Swift:
      struct ClimbRouteDTO: Codable {
          var id = UUID()
          var gradeValue: GradeValue
          var shortDescription: String
      }
    """
    id: UUID = Field(default_factory=uuid4)
    gradeValue: GradeValueModel
    shortDescription: str


class ClimbingWorkoutDTO(WorkoutSessionDTO):
    """
    Swift:
      struct ClimbingWorkoutDTO: WorkoutSessionDTO {
          var sessionDescription: String
          var activity: ActivityTypeEnum = .climbing
          var routes: [ClimbRouteDTO] = []
      }
    """
    activity: Literal["climbing"] = "climbing"
    routes: List[ClimbRouteDTO] = Field(default_factory=list)


class RunningWorkoutDTO(WorkoutSessionDTO):
    """
    Swift:
      struct RunningWorkoutDTO: WorkoutSessionDTO {
          var sessionDescription: String
          var activity: ActivityTypeEnum = .running

          var distanceKm: Double
          var heartRate: Int
          var elevationGain: Int
          var paceMinPerKm: TimeInterval  // seconds per km
      }
    """
    activity: Literal["running"] = "running"
    distanceKm: float
    heartRate: int
    elevationGain: int
    paceMinPerKm: float  # seconds per km


# ----------------------------
# Type-erased wrapper for heterogeneous sessions
# Mirrors AnyWorkoutSessionDTO in Swift
# ----------------------------

AnyWorkoutSessionPayload = Annotated[
    Union[RunningWorkoutDTO, ClimbingWorkoutDTO],
    Field(discriminator="activity"),
]


class AnyWorkoutSessionDTO(RootModel[AnyWorkoutSessionPayload]):
    """
    Swift:
      enum AnyWorkoutSessionDTO: Codable {
          case running(RunningWorkoutDTO)
          case climbing(ClimbingWorkoutDTO)

          var activity: ActivityTypeEnum { ... }
          var sessionDescription: String { get set }
      }

    JSON shape is just the underlying DTO with an "activity" discriminator:
      { "activity": "running", ... }
      { "activity": "climbing", ... }
    """

    # Convenience accessors like the Swift computed properties

    @property
    def activity(self) -> ActivityTypeEnum:
        return self.root.activity

    @property
    def sessionDescription(self) -> str:
        return self.root.sessionDescription

    @sessionDescription.setter
    def sessionDescription(self, value: str) -> None:
        self.root.sessionDescription = value


# ----------------------------
# Container model
# Mirrors DailyWorkoutDTO in Swift
# ----------------------------

class DailyWorkoutDTO(BaseModel):
    """
    Swift:
      struct DailyWorkoutDTO: Codable {
          var tracking_id: UUID
          var date: Date
          var sessions: [AnyWorkoutSessionDTO]
      }

    Python side stores `date` as `datetime`, but accepts:
      - Apple reference seconds (Double)
      - ISO 8601 string
      - datetime
    """
    tracking_id: UUID 
    date: datetime
    sessions: List[AnyWorkoutSessionDTO]

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

    def to_swift_json_obj(
        self,
        *,
        date_strategy: Literal["iso8601", "apple_ref"] = "iso8601",
    ) -> Dict[str, Any]:
        """
        Produce a JSON object matching the Swift DailyWorkoutDTO Codable shape:

          {
            "date": <ISO8601 string or Apple-ref seconds>,
            "sessions": [ { ... running/climbing session ... }, ... ]
          }
        """
        return {
            "date": (
                self._date_to_iso8601(self.date)
                if date_strategy == "iso8601"
                else self._date_to_apple_reference_seconds(self.date)
            ),
            # RootModel.model_dump() returns the underlying DTO shape
            "sessions": [session.model_dump() for session in self.sessions],
        }

    @staticmethod
    def _date_to_iso8601(dt: datetime) -> str:
        return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

    @staticmethod
    def _date_to_apple_reference_seconds(dt: datetime) -> float:
        return (dt.astimezone(timezone.utc) - APPLE_REF).total_seconds()


# ----------------------------
# Convenience JSON helpers
# ----------------------------

def dumps_daily_workout_for_swift(
    model: DailyWorkoutDTO,
    *,
    date_strategy: Literal["iso8601", "apple_ref"] = "iso8601",
) -> str:
    """
    Serialize DailyWorkoutDTO for the Swift client using the same
    field names as the Swift Codable types.
    """
    return json.dumps(
        model.to_swift_json_obj(date_strategy=date_strategy),
        separators=(",", ":"),
        ensure_ascii=False,
    )


def loads_daily_workout_from_swift(s: str) -> DailyWorkoutDTO:
    """
    Parse a DailyWorkoutDTO JSON payload from Swift.

    Expected shape (matches Swift DailyWorkoutDTO + AnyWorkoutSessionDTO):
      {
        "date": <ISO8601 string or Apple-ref seconds>,
        "sessions": [
          { "activity": "running", ... },  # RunningWorkoutDTO
          { "activity": "climbing", ... }, # ClimbingWorkoutDTO
          ...
        ]
      }
    """
    raw = json.loads(s)
    sessions = [AnyWorkoutSessionDTO.model_validate(item) for item in raw["sessions"]]
    return DailyWorkoutDTO(tracking_id=raw["tracking_id"], date=raw["date"], sessions=sessions)
