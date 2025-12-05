# Dojo
A multi sport system for multi sport athletes. The backend is a Python FastAPI that uses the OpenAI Agents SDK, along with a Supermemory vector database. The frontend is an iOS app that lets the user upload their workouts (persisted with Swift Data) and send those workouts to the agent system to be stored in Supermemory . The agents use the users workout history from vector storage, as well as the training plan and other data stored on the device to make informed decisions regarding the users training journey. The agents can update the client side view model and data model by manipulating the context objects. 

## How to run 
1. Make sure you have Mac with XCode.
2. Make an OpenAI account, and generate an API key.
3. Make a Supermemory account, and generate an API key.
4. Put those API keys into a .env file in the Backend folder.
5. Run the command at the top of the main.py file to start a local server.
6. Find your MACs IP address and change the hardcoded URL endpoint in the ChatViewModel.swift file
7. Change the variable in Add Workout View.swift to your Macs IP address as well (line 286).
8. Run the project from XCode either in a simulator or on your physical device.
9. If you haven't run an XCode project before, you'll probably need to do a bunch of other setting up and config changing. 

You can host the backend on Google Cloud run for free, which I was doing, but I took the endpoint down after making this public. 
