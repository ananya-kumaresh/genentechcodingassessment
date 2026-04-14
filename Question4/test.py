from agent import ClinicalTrialDataAgent

# create agent
agent = ClinicalTrialDataAgent()

# test questions
questions = [
    "Give me moderate severity cases",
    "Who had headache?",
    "Show cardiac adverse events"
]

# run tests
for q in questions:
    print("\n========================")
    print("QUESTION:", q)

    result = agent.ask(q)

    print("RESULT:")
    print(result)