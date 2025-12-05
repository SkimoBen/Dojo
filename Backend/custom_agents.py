### PACKAGES 
from __future__ import annotations as _annotations
from dotenv import load_dotenv
from uuid import uuid4 
from datetime import datetime, timezone
from openai.types.shared import Reasoning
from agents import (
    Agent,
    HandoffOutputItem,
    ItemHelpers,
    MessageOutputItem,
    RunContextWrapper,
    Runner,
    ToolCallItem,
    ToolCallOutputItem,
    ModelSettings,
    TResponseInputItem,
    function_tool,
    handoff,
    trace,
)

### FILE IMPORTS
from models import CoordinatorAgentContext, UserDefinedGoal
from planned_workouts_model import DailyWorkoutDTO, AnyWorkoutSessionDTO, ClimbingWorkoutDTO, RunningWorkoutDTO
from memory_management import search_workout_memories, search_workout_documents

load_dotenv() # This explicitly loads the .env file, which contains the API keys. 

context_format = """
{
  "$defs": {
    "ActivityTypeEnum": {
      "enum": [
        "climbing",
        "running"
      ],
      "title": "ActivityTypeEnum",
      "type": "string"
    },
    "AnyWorkoutSessionDTO": {
      "description": "Swift:\n  enum AnyWorkoutSessionDTO: Codable {\n      case running(RunningWorkoutDTO)\n      case climbing(ClimbingWorkoutDTO)\n\n      var activity: ActivityTypeEnum { ... }\n      var sessionDescription: String { get set }\n  }\n\nJSON shape is just the underlying DTO with an \"activity\" discriminator:\n  { \"activity\": \"running\", ... }\n  { \"activity\": \"climbing\", ... }",
      "discriminator": {
        "mapping": {
          "climbing": "#/$defs/ClimbingWorkoutDTO",
          "running": "#/$defs/RunningWorkoutDTO"
        },
        "propertyName": "activity"
      },
      "oneOf": [
        {
          "$ref": "#/$defs/RunningWorkoutDTO"
        },
        {
          "$ref": "#/$defs/ClimbingWorkoutDTO"
        }
      ],
      "title": "AnyWorkoutSessionDTO"
    },
    "ClimbRouteDTO": {
      "description": "Swift:\n  struct ClimbRouteDTO: Codable {\n      var id = UUID()\n      var gradeValue: GradeValue\n      var shortDescription: String\n  }",
      "properties": {
        "id": {
          "format": "uuid",
          "title": "Id",
          "type": "string"
        },
        "gradeValue": {
          "$ref": "#/$defs/GradeValueModel"
        },
        "shortDescription": {
          "title": "Shortdescription",
          "type": "string"
        }
      },
      "required": [
        "gradeValue",
        "shortDescription"
      ],
      "title": "ClimbRouteDTO",
      "type": "object"
    },
    "ClimbingWorkoutDTO": {
      "description": "Swift:\n  struct ClimbingWorkoutDTO: WorkoutSessionDTO {\n      var sessionDescription: String\n      var activity: ActivityTypeEnum = .climbing\n      var routes: [ClimbRouteDTO] = []\n  }",
      "properties": {
        "sessionDescription": {
          "title": "Sessiondescription",
          "type": "string"
        },
        "activity": {
          "const": "climbing",
          "default": "climbing",
          "title": "Activity",
          "type": "string"
        },
        "routes": {
          "items": {
            "$ref": "#/$defs/ClimbRouteDTO"
          },
          "title": "Routes",
          "type": "array"
        }
      },
      "required": [
        "sessionDescription"
      ],
      "title": "ClimbingWorkoutDTO",
      "type": "object"
    },
    "DailyWorkoutDTO": {
      "description": "Swift:\n  struct DailyWorkoutDTO: Codable {\n      var tracking_id: UUID\n      var date: Date\n      var sessions: [AnyWorkoutSessionDTO]\n  }\n\nPython side stores `date` as `datetime`, but accepts:\n  - Apple reference seconds (Double)\n  - ISO 8601 string\n  - datetime",
      "properties": {
        "tracking_id": {
          "format": "uuid",
          "title": "Tracking Id",
          "type": "string"
        },
        "date": {
          "format": "date-time",
          "title": "Date",
          "type": "string"
        },
        "sessions": {
          "items": {
            "$ref": "#/$defs/AnyWorkoutSessionDTO"
          },
          "title": "Sessions",
          "type": "array"
        }
      },
      "required": [
        "tracking_id",
        "date",
        "sessions"
      ],
      "title": "DailyWorkoutDTO",
      "type": "object"
    },
    "FitnessLevel": {
      "properties": {
        "activity": {
          "$ref": "#/$defs/ActivityTypeEnum"
        },
        "userDefinedFitnessLevel": {
          "anyOf": [
            {
              "type": "string"
            },
            {
              "type": "null"
            }
          ],
          "default": null,
          "title": "Userdefinedfitnesslevel"
        },
        "userDefinedFitnessLevelUpdatedDate": {
          "anyOf": [
            {
              "format": "date-time",
              "type": "string"
            },
            {
              "type": "null"
            }
          ],
          "default": null,
          "title": "Userdefinedfitnesslevelupdateddate"
        },
        "agentDefinedFitnessLevel": {
          "anyOf": [
            {
              "type": "string"
            },
            {
              "type": "null"
            }
          ],
          "default": null,
          "title": "Agentdefinedfitnesslevel"
        },
        "agentFitnessLevelUpdatedDate": {
          "anyOf": [
            {
              "format": "date-time",
              "type": "string"
            },
            {
              "type": "null"
            }
          ],
          "default": null,
          "title": "Agentfitnesslevelupdateddate"
        }
      },
      "required": [
        "activity"
      ],
      "title": "FitnessLevel",
      "type": "object"
    },
    "GradeValueModel": {
      "description": "Wire/object form matching Swift:\n{\n  \"scale\": \"yds\" | \"v\",\n  \"value\": \"5.10a\" | \"V7\"\n}\n\nAlso accepts a plain string \"V7\" or \"5.10a\" in requests (will infer scale).",
      "properties": {
        "scale": {
          "enum": [
            "yds",
            "v"
          ],
          "title": "Scale",
          "type": "string"
        },
        "value": {
          "title": "Value",
          "type": "string"
        }
      },
      "required": [
        "scale",
        "value"
      ],
      "title": "GradeValueModel",
      "type": "object"
    },
    "RunningWorkoutDTO": {
      "description": "Swift:\n  struct RunningWorkoutDTO: WorkoutSessionDTO {\n      var sessionDescription: String\n      var activity: ActivityTypeEnum = .running\n\n      var distanceKm: Double\n      var heartRate: Int\n      var elevationGain: Int\n      var paceMinPerKm: TimeInterval  // seconds per km\n  }",
      "properties": {
        "sessionDescription": {
          "title": "Sessiondescription",
          "type": "string"
        },
        "activity": {
          "const": "running",
          "default": "running",
          "title": "Activity",
          "type": "string"
        },
        "distanceKm": {
          "title": "Distancekm",
          "type": "number"
        },
        "heartRate": {
          "title": "Heartrate",
          "type": "integer"
        },
        "elevationGain": {
          "title": "Elevationgain",
          "type": "integer"
        },
        "paceMinPerKm": {
          "title": "Paceminperkm",
          "type": "number"
        }
      },
      "required": [
        "sessionDescription",
        "distanceKm",
        "heartRate",
        "elevationGain",
        "paceMinPerKm"
      ],
      "title": "RunningWorkoutDTO",
      "type": "object"
    },
    "UserDefinedGoal": {
      "properties": {
        "id": {
          "format": "uuid",
          "title": "Id",
          "type": "string"
        },
        "goalActivity": {
          "$ref": "#/$defs/ActivityTypeEnum"
        },
        "title": {
          "title": "Title",
          "type": "string"
        },
        "description": {
          "title": "Description",
          "type": "string"
        },
        "goalDeadline": {
          "format": "date-time",
          "title": "Goaldeadline",
          "type": "string"
        },
        "isCompleted": {
          "title": "Iscompleted",
          "type": "boolean"
        }
      },
      "required": [
        "id",
        "goalActivity",
        "title",
        "description",
        "goalDeadline",
        "isCompleted"
      ],
      "title": "UserDefinedGoal",
      "type": "object"
    }
  },
  "properties": {
    "userId": {
      "title": "Userid",
      "type": "string"
    },
    "goals": {
      "items": {
        "$ref": "#/$defs/UserDefinedGoal"
      },
      "title": "Goals",
      "type": "array"
    },
    "currentTrainingPlan": {
      "items": {
        "$ref": "#/$defs/DailyWorkoutDTO"
      },
      "title": "Currenttrainingplan",
      "type": "array"
    },
    "activityFitnessLevels": {
      "items": {
        "$ref": "#/$defs/FitnessLevel"
      },
      "title": "Activityfitnesslevels",
      "type": "array"
    }
  },
  "required": [
    "userId",
    "goals",
    "currentTrainingPlan",
    "activityFitnessLevels"
  ],
  "title": "CoordinatorAgentContext",
  "type": "object"
}
"""


### TOOLS 
@function_tool 
async def create_climbing_workout(context: RunContextWrapper[CoordinatorAgentContext], 
                                  climbing_workout_json: str,
                                  date: datetime) -> None:
    """
    A tool that accepts a DailyWorkoutDTO object representing a single DailyWorkout,
    and creates a new DailyWorkout, and then appends it to the currentTrainingPlan in the coordinator context.
    Args:
        climbing_workout_json: The single climbing workout as a JSON string. For example:
        {
            "sessionDescription": "Evening session focusing on overhang endurance.",
            "activity": "climbing",
            "routes": [
                {
                "id": "3f5c8c5e-1e52-4e74-b5c5-8dc534d61a1e",
                "gradeValue": {
                    "scale": "yds",
                    "value": "5.11b"
                },
                "shortDescription": "Steep overhang with small crimps."
                },
                {
                "id": "d2a4f0b1-c1df-4470-8e63-4e2af6b8cd75",
                "gradeValue": {
                    "scale": "v",
                    "value": "V5"
                },
                "shortDescription": "Powerful boulder problem on slopers."
                }
            ]
        }
        date: The date of the climbing workout.

    """
    new_climbing_workout = AnyWorkoutSessionDTO.model_validate_json(climbing_workout_json)
    #Incomplete



@function_tool
async def create_workout(context: RunContextWrapper[CoordinatorAgentContext], new_workout_json: str) -> str:
    """
    A tool that accepts a JSON string representing a single DailyWorkout,
    and creates a new DailyWorkout, and then appends it to the currentTrainingPlan in the coordinator context.
    Args:
        updated_goal_json: The single updates goal.
    """
    try:
        # Parse incoming JSON into a PlannedWorkout
        new_workout = AnyWorkoutSessionDTO.model_validate_json(new_workout_json)
        
        plan = context.context.currentTrainingPlan
        print(plan)
        # If there's no training plan at all or it's empty, create the first day
        if not plan:
            first_day = DailyWorkoutDTO(
                tracking_id=uuid4(),
                sessions=[new_workout],
                date=datetime.now(timezone.utc),
            )
            context.context.currentTrainingPlan = [first_day]
        else:
            # Append to the first existing day by default
            plan[0].sessions.append(new_workout)

        # Return the updated coordinator context as JSON for LLM consumption
        return context.context.model_dump_json(indent=1)

    except Exception as e:
        # Return a simple error string so the LLM/toolchain can reason about failure
        print(f"error: failed to create workout - {e}")
        return f"error: failed to create workout - {e}"
    
@function_tool
async def update_workout(context: RunContextWrapper[CoordinatorAgentContext], updated_workout_json: str) -> str:
    """
    A tool that accepts a JSON string representing a single PlannedWorkout,
    updates the matching PlannedWorkout in the coordinator context (by id) or
    appends it to the first day if not found, and returns the updated
    CoordinatorAgentContext as JSON.
    Args:
        updated_workout_json: The single updated planned workout.
        Remember that the JSON string will either be for a running workout or a climbing workout which will look like one of these: 
        {
            "climbing" : {
              "id" : "556753E8-3E2A-4716-945D-65E77DA47398",
              "routes" : [
                {
                  "id" : "E0CADBCF-B500-4902-AA00-D1BFB8ED80A8",
                  "shortDescription" : "Warm-up circuit – focus on smooth footwork. Then do some more super nails routes and go for the send",
                  "grade" : "5.10a"
                },
                {
                  "id" : "A32FE64B-24AE-482A-B347-1E9CEF8D2D1C",
                  "shortDescription" : "Compression boulder with big slopers",
                  "grade" : "5.11b"
                },
                {
                  "id" : "3C3E8AAE-6A14-40FE-9316-EEB418BBF50A",
                  "shortDescription" : "Steep overhangs and power endurance",
                  "grade" : "V5"
                },
                {
                  "id" : "498678E1-C5F9-48D2-A490-BCEAA324197C",
                  "shortDescription" : "Crimpy face climb to cool down",
                  "grade" : "V4"
                }
              ],
              "sessionDescription" : "Focus on a solid warm up followed by a few limit bouldering problems. This could be tricky but you should be able to flash 12a on the first go. Cool down with a face climb."
            }
        }
        OR
        {
            "running" : {
              "distanceKm" : 24,
              "id" : "B11290D6-B41B-40BA-AA99-C8B59F025D59", // UUID
              "heartRate" : 123, // BPM
              "sessionDescription" : "Aim for a long zone 2 run, you should be kinda fast by now.",
              "elevationGain" : 50, // in meters
              "paceMinPerKm" : 400 // in seconds per km
            }
        }
    """
    try:
        # parse incoming JSON into a PlannedWorkout
        updated_workout = AnyWorkoutSessionDTO.model_validate_json(updated_workout_json)

        # find existing PlannedWorkout by id inside each DailyWorkout.workouts and update
        found = False
        for day in context.context.currentTrainingPlan:
            for idx, pw in enumerate(day.sessions):
                if pw.id == updated_workout.tracking_id:
                    # replace the PlannedWorkout inside the day's workouts list
                    day.sessions[idx] = updated_workout
                    found = True
                    break
            if found:
                break

        # if not found, append to the first day (or return an error if no days exist)
        if not found:
            if context.context.currentTrainingPlan:
                context.context.currentTrainingPlan[0].sessions.append(updated_workout)
            else:
                return "error: no training plan present to append workout"

        # return the updated coordinator context as JSON for LLM consumption
        return context.context.model_dump_json(indent=1)

    except Exception as e:
        # return a simple error string so the LLM/toolchain can reason about failure
        return f"error: failed to update workouts - {e}"


@function_tool
async def get_context(context: RunContextWrapper[CoordinatorAgentContext]) -> str:
    """
    A tool that retrieves the user's current goals and training plan.
    """
    return context.context.model_dump_json(indent=1)



@function_tool
async def update_goal(context: RunContextWrapper[CoordinatorAgentContext], updated_goal_json: str) -> str:
    """
    A tool that accepts a JSON string representing a single UserDefinedGoal,
    updates the matching goal in the coordinator context (by id) or appends it
    if not found, and returns the updated CoordinatorAgentContext as JSON.
    Args:
        updated_goal_json: The single updates goal.
    """
    try:
        # parse incoming JSON into a UserDefinedGoal
        updated_goal = UserDefinedGoal.model_validate_json(updated_goal_json)

        # find existing goal by id and update, otherwise append
        found = False
        for idx, g in enumerate(context.context.goals):
            if g.id == updated_goal.id:
                # replace the goal with the new validated model
                context.context.goals[idx] = updated_goal
                found = True
                
                break

        if not found:
            context.context.goals.append(updated_goal)

        # return the updated coordinator context as JSON for LLM consumption
        return context.context.model_dump_json(indent=1)

    except Exception as e:
        # return a simple error string so the LLM/toolchain can reason about failure
        return f"error: failed to update goals - {e}"

@function_tool
async def update_context(context: RunContextWrapper[CoordinatorAgentContext], new_context_json_string: str) -> str:
    """
    A tool that accepts a new CoordinatorAgentContext,
    replaces the existing context with it, and returns a success or error message. If you get an error because you messed up the JSON formatting, just try again with correct JSON. Never change the field called userDefinedFitnessLevel. You are in charge of the agentDefinedFitnessLevel.
    Args:
        new_context_json_string: The new CoordinatorAgentContext represented as a JSON string, it must follow the context format provided. 
    """
    print("Update Context Tool Called")
    print(new_context_json_string)
    
    try:
        new_context = CoordinatorAgentContext.model_validate_json(new_context_json_string)

        # return the updated coordinator context as JSON for LLM consumption
        # mutate wrapper.context in place
        for field, value in new_context.model_dump().items():
            setattr(context.context, field, value)
        print("context.context inside the update_context tool:")
        print(context.context)
        return "Successfully updated context."

    except Exception as e:
        # return a simple error string so the LLM/toolchain can reason about failure
        return f"error: failed to update context - {e}"

@function_tool 
async def search_workout_history(userId: str, query: str, activity: str, limit: int) -> str: 
    """
    A tool that searches the users workout history based on your input parameters. 
    Args: 
    userId: The users id, which you have access to. 
    query: A short text query to use in the vector space. If you want all the workout history just search for the activity name.
    activity: The activity type you're searching for (your specialty as a coach).
    limit: The maximum number of returned workout results you want.
    Returns:
        A JSON string representing the search results from the user's workout history. Note that the avgPacePerKm
        field is in minutes per kilometer format (e.g., 4.5 means 4 minutes and 30 seconds per kilometer).
    """
    print("Coach Query: ", query, activity, "userId: ", userId)
    workout_documents = search_workout_documents(userId=userId, query=query, activity=activity, limit=limit)
    workout_memories = search_workout_memories(userId=userId, query=query, activity=activity, limit=limit)
    workout_history = "---Documents---\n" + workout_documents + "---Memories---\n" + workout_memories
    return workout_history

### AGENTS

context_updator = Agent[CoordinatorAgentContext](
    name = "context_updator",
    model = "gpt-5-mini",
    instructions=f" You are an agent that is in charge of updating the coordinator context based on new information provided to you. Use the get context tool first to make sure you have the latest context, then make the updates as specified. This is the format for the context: {context_format} \n, FYI, todays date is {datetime.now(timezone.utc).isoformat()}. When you update the training plan, you shouldn't delete existing workouts unless told to. If they ask you to add a workout, you need to regenerate the entire context with the new workout added to the currentTrainingPlan field. If you are updating a goal, make sure you keep all the other goals the same except for the one you're updating. This is also true for the fitness levels. Never change the field called userDefinedFitnessLevel. You are in charge of the agentDefinedFitnessLevel.",
    handoff_description="An agent who is responsible for updating the context. Just specify the fields that you want to update, and provide the new values.",
    tools = [
        get_context,
        update_context
    ]
)

running_coach = Agent[CoordinatorAgentContext](
    name="running_coach",
    model="gpt-5-mini",
    instructions=f"""
    You are a running coach with expertise in training plans for running.
    You are specifically in charge of making informed decisions about running training based on the users running workout history which you can find using the tool provided. Remember that this is a conversation, so keep your responses short and to the point.
    """,
    handoff_description="A running coach that has in depth knowledge of the users running history.",
    model_settings = ModelSettings(verbosity="low", reasoning=Reasoning(effort= "minimal")),
    tools=[
        search_workout_history,
        get_context,
        context_updator.as_tool(
            tool_name="context_updator",
            tool_description="An agent who is responsible for updating the context. Just specify the fields that you want to update, and provide the new values."
        )
    ]
)



climbing_coach = Agent[CoordinatorAgentContext](
    name="climbing_coach",
    model="gpt-5-mini",
    instructions=f"""
    You are a climbing coach with expertise in training plans for climbing.
    You are specifically in charge of making informed decisions about climbing training based on the users climbing workout history which you can find using the tool provided.  
    """,
    handoff_description="A rock climbing coach that has in depth knowledge of the users climbing history.",
    model_settings = ModelSettings(verbosity="low", reasoning=Reasoning(effort= "minimal")),
    tools=[
        search_workout_history, 
        get_context,
        context_updator.as_tool(
            tool_name="context_updator",
            tool_description="An agent who is responsible for updating the context. Just specify the fields that you want to update, and provide the new values."
        )
    ],
    
)

coordinator_chatbot_agent = Agent[CoordinatorAgentContext](
    name="coordinator_chatbot_agent",
    model="gpt-5-mini",
    instructions=f"""
    You are a coordinator with expertise in fitness and training plans for climbing and running.
    You are specifically in charge of talking to the user to understand their needs and answer questions
    they might have about their training plan. You should almost always begin by using the 'get_context' tool so that you can see their current goals and training plan. 
    
    Sometimes, the user may ask you something about a specific sport that they're training for. In this case you should consider asking the coach for that activity for help. They will have more expertise than you about the sport, and will be able to tell you the users training history. Remember that this is a conversation, so keep your responses short and to the point.
    If they tell you make a goal, or workout, or fitness level, then use the update_context tool to update the goal. You do not have access to the users workout history in the context, you have to ask the running_coach or climbing_coach for that information. For example if the user asks why their knee hurts, you can ask the running_coach about their running history to see if there are any clues there. If the user tells you to make a goal or workout and they give you the details, then you should just do that without asking the coach.
    """,
    tools=[
        running_coach.as_tool(
            tool_name="running_coach",
            tool_description="A running coach that has in depth knowledge of the users running history, and their running training plan. Make sure you give them the userId in lowercase.",
        ),
        climbing_coach.as_tool(
            tool_name="climbing_coach",
            tool_description="A climbing coach that has in depth knowledge of the users climbing history, and their climbing training plan. Make sure you give them the userId.",
        ),
        get_context,
        context_updator.as_tool(
            tool_name="context_updator",
            tool_description="An agent who is responsible for updating the context. Just specify the fields that you want to update, and provide the new values."
        )

    ]
)



# test_coordinator = Agent[CoordinatorAgentContext](
#     name="tets_coordinator",
#     model="gpt-5-nano",
#     instructions=f"""
#     You are a simple training helper. Reply in 1 sentence maximum.
#     """,
#     tools=[
#         get_training_goals_and_plan
#     ]
# )

test_coordinator = Agent(
    name="tets_coordinator",
    model="gpt-5-nano",
    instructions=f"""
    You are a simple training helper. Reply in 1 sentence maximum.
    """
)


