"""Builds assets/questions.json for the India learner's licence (LL) test.

All questions are original, written from the Motor Vehicles Act, 1988, the
Motor Vehicles (Driving) Regulations, 2017, and IRC:67 road signs. Sign
questions use the artwork drawn by rto_signs.py.
"""
import json
import os
import random

from rto_signs import SIGNS

RULES = "Rules of the road"
SAFE = "Safe driving"
DOCS = "Licence and documents"
SIGN_CATS = {"mandatory": "Mandatory signs", "cautionary": "Warning and information signs", "informatory": "Warning and information signs"}

# (category, question, right answer, [three wrong answers], short explanation)
WRITTEN = [
    (RULES, "On Indian roads, which side of the road should you normally drive on?", "The left side",
     ["The right side", "The middle of the road", "Any side that is free"],
     "India drives on the left. Keep to the left and let faster traffic pass on your right."),
    (RULES, "From which side should you normally overtake another vehicle?", "From the right",
     ["From the left", "From either side", "From the footpath side"],
     "Overtake from the right. You may pass on the left only when the vehicle ahead has signalled a right turn and moved to turn."),
    (RULES, "The vehicle ahead has signalled a right turn and moved to the centre. How may you pass it?",
     "On its left, carefully", ["On its right, at speed", "You must never pass it", "By sounding the horn and pushing past"],
     "When a vehicle is turning right, you may pass it on the left if the way is clear."),
    (RULES, "When is overtaking not allowed?", "When the road ahead is not clearly visible",
     ["On a straight, clear road", "When the vehicle ahead signals you to pass", "On a wide highway with no traffic"],
     "Do not overtake at bends, hill tops, junctions, pedestrian crossings or whenever you cannot see the road ahead clearly."),
    (RULES, "Another vehicle is overtaking you. What should you do?", "Keep left and do not speed up",
     ["Speed up so it cannot pass", "Move to the right", "Brake suddenly"],
     "Help the overtaking vehicle pass safely. Never increase your speed while being overtaken."),
    (RULES, "A pedestrian is waiting to cross at a zebra crossing. What should you do?",
     "Slow down and stop to let them cross", ["Sound the horn and continue", "Speed up to pass before they step out",
                                               "Flash your headlights and continue"],
     "Pedestrians on or waiting at a zebra crossing have the right of way."),
    (RULES, "An ambulance or fire engine is coming with its siren on. What should you do?",
     "Move to the side of the road and let it pass", ["Follow closely behind it", "Keep going at the same speed",
                                                      "Stop in the middle of the road"],
     "Emergency vehicles have priority. Give way by pulling to the side."),
    (RULES, "What does a steady red traffic light mean?", "Stop before the stop line",
     ["Slow down and go", "Go if the road is clear", "Turn left only"],
     "Stop behind the stop line and wait for green."),
    (RULES, "What does a steady amber (yellow) traffic light mean?", "Stop, unless you are too close to stop safely",
     ["Speed up to cross", "Go, the light is about to turn green", "Turn right only"],
     "Amber warns that red is next. Stop if you safely can."),
    (RULES, "What does a flashing amber traffic light mean?", "Slow down and proceed with caution",
     ["Stop and wait", "The signal is broken, so stop", "Pedestrians only"],
     "A flashing amber light means go ahead carefully, watching for other traffic."),
    (RULES, "What does a flashing red traffic light mean?", "Stop, then go when it is safe",
     ["Go without stopping", "Slow down only", "Reverse"],
     "Treat a flashing red like a stop sign."),
    (RULES, "The traffic light is green but a traffic police officer signals you to stop. What do you do?",
     "Obey the police officer and stop", ["Obey the green light and go", "Sound the horn", "Turn around"],
     "Signals from a traffic police officer take priority over traffic lights."),
    (RULES, "At a roundabout, which vehicles should you give way to?", "Vehicles already in the roundabout, coming from your right",
     ["Vehicles on your left", "No one, if you are faster", "Only buses"],
     "In India, traffic moves clockwise around a roundabout. Give way to vehicles coming from your right."),
    (RULES, "At a junction with no signals or signs, whom should you give way to?", "Traffic coming from your right",
     ["Traffic coming from your left", "Whoever honks first", "Smaller vehicles"],
     "At an uncontrolled junction, give way to traffic on your right and to vehicles on the main road."),
    (RULES, "You are entering a main road from a side road. What should you do?", "Give way to traffic on the main road",
     ["Enter quickly while honking", "Expect main road traffic to stop for you", "Enter without looking"],
     "Traffic on the main road has priority."),
    (RULES, "What does a continuous (solid) line in the centre of the road mean?", "Do not cross it or overtake",
     ["You may overtake", "Parking is allowed", "It marks a bus lane"],
     "A solid centre line means no crossing or overtaking."),
    (RULES, "What does a broken (dashed) white line in the centre of the road mean?", "You may cross it to overtake when safe",
     ["You must never cross it", "Stop at the line", "Road ends ahead"],
     "Broken lines may be crossed when it is safe to do so."),
    (RULES, "Where should you stop at a red light?", "Before the stop line",
     ["On the zebra crossing", "In the middle of the junction", "After the stop line"],
     "Never stop on the pedestrian crossing. Stop behind the stop line."),
    (RULES, "Where is parking not allowed?", "Near a road junction or bend",
     ["In a marked parking area", "In your own garage", "At a parking lot"],
     "Do not park near junctions, bends, hill tops, bus stops, pedestrian crossings, fire hydrants, or on a footpath."),
    (RULES, "Is parking allowed on a footpath?", "No, never", ["Yes, for two-wheelers", "Yes, for 10 minutes", "Yes, at night"],
     "Footpaths are for pedestrians. Parking on them is not allowed."),
    (RULES, "Where should you not park your vehicle?", "In front of a hospital entrance",
     ["In a marked parking bay", "In a paid parking lot", "On your own property"],
     "Never block hospital entrances, fire hydrants, bus stops or gates."),
    (RULES, "Where is the use of the horn prohibited?", "Near hospitals and courts",
     ["On highways", "At night only", "On bridges"],
     "Areas near hospitals, courts and schools are silence zones. Do not sound your horn there."),
    (RULES, "When should the horn be used?", "Only when necessary, to warn of danger",
     ["Continuously in traffic", "To greet friends", "When the signal turns green"],
     "Use the horn sparingly. Needless or continuous honking is not allowed."),
    (RULES, "Are pressure horns or multi-tone horns allowed?", "No", ["Yes", "Yes, on highways", "Yes, at night"],
     "Air pressure horns and multi-tone horns are not allowed on vehicles."),
    (RULES, "How many people may ride on a motorcycle?", "The rider and one pillion rider",
     ["The rider and two pillion riders", "Any number if they fit", "Only the rider"],
     "A two-wheeler may carry only one pillion rider, seated properly behind the rider."),
    (RULES, "What should you do at an unmanned railway level crossing?", "Stop, look both ways, then cross when it is clear",
     ["Cross fast without stopping", "Sound the horn and cross", "Follow the vehicle ahead closely"],
     "At an unmanned crossing, stop, check both directions for trains, and cross only when it is safe."),
    (RULES, "The gate of a railway level crossing is closed. What should you do?", "Stop and wait until it opens",
     ["Go around the gate", "Cross under the barrier", "Honk until it opens"],
     "Never try to cross a closed level-crossing gate."),
    (RULES, "You want to turn right. Where should your vehicle be?", "Near the centre of the road",
     ["At the far left edge", "On the footpath", "On the wrong side of the road"],
     "Before turning right, move towards the centre of the road and signal."),
    (RULES, "You want to turn left. Where should your vehicle be?", "Close to the left side of the road",
     ["In the centre of the road", "On the right side", "Anywhere"],
     "Keep to the left before turning left."),
    (RULES, "What does a driver extending the right arm straight out of the window mean?", "I am turning right",
     ["I am turning left", "I am stopping", "You may overtake"],
     "An arm held straight out to the right signals a right turn."),
    (RULES, "A driver moves the right arm up and down, palm facing down. What does it mean?", "I am slowing down",
     ["I am turning right", "Overtake me now", "I am reversing"],
     "Moving the arm up and down signals that the vehicle is slowing down."),
    (RULES, "Is driving in reverse allowed on a one-way road?", "No", ["Yes, always", "Yes, at night", "Yes, for short distances"],
     "Do not reverse into or along a one-way road."),
    (RULES, "On a one-way road, can you drive against the direction of traffic?", "No",
     ["Yes, if it is a shortcut", "Yes, on a two-wheeler", "Yes, at night"],
     "Driving against the flow on a one-way road is an offence and very dangerous."),
    (RULES, "On a hill road, who should normally get the right of way?", "Vehicles going uphill",
     ["Vehicles going downhill", "The vehicle that honks first", "The smaller vehicle"],
     "On narrow hill roads, give way to vehicles coming uphill, since restarting on a slope is harder."),

    (SAFE, "What is the legal blood alcohol limit for driving in India?", "30 mg per 100 ml of blood",
     ["80 mg per 100 ml of blood", "100 mg per 100 ml of blood", "There is no limit"],
     "Driving with more than 30 mg of alcohol per 100 ml of blood is an offence. The safest choice is not to drink at all."),
    (SAFE, "Is it allowed to use a hand-held mobile phone while driving?", "No",
     ["Yes, for short calls", "Yes, at traffic lights", "Yes, on highways"],
     "Using a hand-held phone while driving is an offence. Pull over safely if you must make a call."),
    (SAFE, "Who must wear a helmet on a motorcycle?", "Both the rider and the pillion rider",
     ["Only the rider", "Only on highways", "Only at night"],
     "Rider and pillion must wear a properly fastened helmet."),
    (SAFE, "Who should wear a seat belt in a car?", "The driver and all passengers",
     ["Only the driver", "Only front seat passengers on highways", "No one in the city"],
     "Seat belts save lives. Everyone in the car should wear one."),
    (SAFE, "When driving at night and a vehicle comes from the front, what should you do with your headlights?",
     "Switch to dipped (low) beam", ["Keep high beam on", "Switch off the headlights", "Flash high beam repeatedly"],
     "High beam dazzles oncoming drivers. Dip your lights."),
    (SAFE, "How much distance should you keep from the vehicle in front?", "Enough to stop safely if it brakes suddenly",
     ["As close as possible", "Exactly one metre", "No gap is needed in slow traffic"],
     "Keep a safe gap, and increase it in rain, fog or at higher speed."),
    (SAFE, "What should you do when driving in thick fog?", "Slow down and use dipped headlights or fog lamps",
     ["Use high beam", "Drive fast to get out of the fog", "Follow the vehicle ahead very closely"],
     "High beam reflects off fog and reduces visibility. Slow down and use low beam or fog lamps."),
    (SAFE, "What should you do when approaching a bend?", "Slow down and keep left",
     ["Speed up", "Overtake the vehicle ahead", "Move to the right side"],
     "Reduce speed before the bend and stay on your side."),
    (SAFE, "What are hazard warning lights used for?", "To warn others that your vehicle is stopped and is a hazard",
     ["To park anywhere you like", "To drive faster", "To signal a lane change"],
     "Use hazard lights when your vehicle has broken down or is stopped in an unsafe place."),
    (SAFE, "Why are rear-view mirrors fitted?", "To see traffic behind you",
     ["To look at yourself", "To see the road ahead", "To check the tyres"],
     "Check your mirrors often, especially before changing lanes, turning or slowing down."),
    (SAFE, "When should you check your mirrors?", "Before changing lanes, turning or slowing down",
     ["Only when parking", "Never while moving", "Only on highways"],
     "Mirror, signal, then manoeuvre."),
    (SAFE, "A school bus has stopped to let children get off. What should you do?", "Slow down and be ready to stop",
     ["Speed up to pass it", "Sound the horn continuously", "Overtake from the left"],
     "Children may run across the road. Drive slowly and carefully."),
    (SAFE, "Near a school, how should you drive?", "Slowly and carefully, watching for children",
     ["Fast, to clear the area quickly", "Using the horn all the time", "As usual"],
     "School zones need extra care and low speed."),
    (SAFE, "What should you do if you feel sleepy while driving?", "Stop safely and rest",
     ["Drive faster to reach sooner", "Open the window and continue", "Play loud music and continue"],
     "Drowsy driving causes many crashes. Take a break."),
    (SAFE, "The road is wet after rain. What should you do?", "Drive slower and keep a bigger gap",
     ["Drive at normal speed", "Brake hard on curves", "Follow closely behind others"],
     "Wet roads are slippery and need longer stopping distances."),
    (SAFE, "Your brakes fail on a slope. What is the safest thing to do?", "Change to a lower gear and use the hand brake gently",
     ["Switch off the engine and steer", "Shift to neutral", "Jump out"],
     "Lower gears use engine braking to slow you. Apply the hand brake gradually."),
    (SAFE, "You are involved in an accident and someone is injured. What should you do?",
     "Get medical help for the injured and inform the police", ["Leave the place quickly", "Wait for the other driver to act",
                                                                   "Move the vehicles and continue"],
     "The driver must help get the injured to medical care and report the accident to the police."),
    (SAFE, "Within how much time should a road accident be reported to the police?", "Within 24 hours",
     ["Within 7 days", "Within a month", "There is no need"],
     "If not reported on the spot, an accident must be reported to the nearest police station within 24 hours."),
    (SAFE, "What is a \"Good Samaritan\" under Indian road law?", "A bystander who helps an accident victim in good faith",
     ["A traffic police officer", "An insurance agent", "The owner of the vehicle"],
     "The law protects people who help road accident victims in good faith from harassment and liability."),
    (SAFE, "What is the all-in-one emergency number in India?", "112", ["100 only", "999", "911"],
     "Dial 112 for police, fire or ambulance help."),
    (SAFE, "Why should you not drive with worn-out tyres?", "They can skid or burst, causing an accident",
     ["They use more fuel only", "They make the car louder", "There is no problem"],
     "Worn tyres have less grip, especially on wet roads."),
    (SAFE, "When should you use the indicator?", "Before turning or changing lanes",
     ["After you have turned", "Only at night", "Only on highways"],
     "Signal early so others know what you plan to do."),
    (SAFE, "Can a vehicle carry more passengers or load than it is permitted to?", "No",
     ["Yes, for short trips", "Yes, if the driver is careful", "Yes, at night"],
     "Overloading makes a vehicle unstable and is an offence."),

    (DOCS, "How long is a learner's licence valid?", "6 months", ["1 month", "1 year", "5 years"],
     "A learner's licence is valid for six months."),
    (DOCS, "After getting a learner's licence, when can you apply for a permanent driving licence?",
     "After 30 days", ["Immediately", "After 6 months only", "After 1 year"],
     "You can take the driving test for a permanent licence 30 days after the learner's licence is issued, and before it expires."),
    (DOCS, "What must a learner display on the vehicle?", "An \"L\" sign on the front and back",
     ["A red flag", "A \"P\" sign", "Nothing"],
     "The letter L in red on a white background must be shown on the front and rear of the vehicle."),
    (DOCS, "A learner is driving a car. Who must sit beside them?", "A person holding a valid driving licence for that vehicle",
     ["Any adult", "No one", "A child"],
     "A learner driving a car must have a licensed driver beside them who can take control."),
    (DOCS, "What is the minimum age to get a licence for a motorcycle with gears?", "18 years",
     ["16 years", "21 years", "25 years"],
     "You must be 18 for a licence for motorcycles with gear and for cars."),
    (DOCS, "At what age can you get a licence for a gearless two-wheeler up to 50 cc, with a parent's consent?",
     "16 years", ["14 years", "18 years", "12 years"],
     "At 16 you can get a licence for a gearless motorcycle with an engine up to 50 cc, with consent of a parent or guardian."),
    (DOCS, "Which documents must you carry while driving a private vehicle?",
     "Driving licence, registration certificate, insurance and PUC certificate",
     ["Only your Aadhaar card", "Only the vehicle's bill", "Only the insurance"],
     "Carry your licence, RC, insurance certificate and Pollution Under Control (PUC) certificate."),
    (DOCS, "Are digital documents in DigiLocker or mParivahan accepted?", "Yes, they are valid",
     ["No, only paper copies", "Only in some cities", "Only for two-wheelers"],
     "Documents in DigiLocker or mParivahan are accepted as valid by traffic police."),
    (DOCS, "Which insurance is compulsory for every motor vehicle?", "Third-party insurance",
     ["Comprehensive insurance only", "Life insurance", "No insurance is compulsory"],
     "At least third-party insurance is required by law."),
    (DOCS, "What does PUC stand for?", "Pollution Under Control", ["Public Use Certificate", "Permit Under Control",
                                                                    "Police Use Certificate"],
     "A PUC certificate shows your vehicle's emissions are within limits."),
    (DOCS, "How long is the registration of a new private car valid?", "15 years", ["5 years", "10 years", "For life"],
     "Registration of a non-transport vehicle is valid for 15 years and can then be renewed."),
    (DOCS, "Can you drive a vehicle with an expired driving licence?", "No", ["Yes, for one year", "Yes, in your own city",
                                                                              "Yes, if you are careful"],
     "Renew your licence before it expires."),
    (DOCS, "Can you lend your vehicle to someone without a driving licence?", "No",
     ["Yes, if they are an adult", "Yes, for short trips", "Yes, if they know how to drive"],
     "The owner can be held responsible for letting an unlicensed person drive."),
    (DOCS, "Can a person under 18 drive a car on public roads?", "No",
     ["Yes, with a parent's consent", "Yes, at night", "Yes, on small roads"],
     "A licence to drive a car is issued only from age 18. Guardians or owners can be penalised if a minor drives."),
]


# Extra wrong answers so small sign groups still get three believable options.
EXTRA_WRONG = {
    "mandatory": [],
    "cautionary": ["Steep ascent ahead", "Slippery road"],
    "informatory": ["Hospital", "Petrol pump", "Bus stop", "Eating place", "No parking", "Parking prohibited for cars"],
}


def sign_questions(rng):
    out = []
    by_group = {}
    for key, (meaning, group, _) in SIGNS.items():
        by_group.setdefault(group, []).append(meaning)
    for key, (meaning, group, _) in SIGNS.items():
        others = [m for m in by_group[group] + EXTRA_WRONG[group] if m != meaning]
        wrong = rng.sample(others, 3)
        out.append((SIGN_CATS[group], "What does this sign mean?", meaning, wrong, None, key))
    return out


def main():
    rng = random.Random(7)
    items = sign_questions(rng) + [(c, q, a, w, e, None) for c, q, a, w, e in WRITTEN]
    cats = list(dict.fromkeys(SIGN_CATS.values())) + [RULES, SAFE, DOCS]
    items.sort(key=lambda x: cats.index(x[0]))
    questions = []
    for i, (cat, text, right, wrong, why, sign) in enumerate(items, start=1):
        assert len(wrong) == 3 and right not in wrong and len(set(wrong)) == 3, text
        q = {"id": i, "category": cat, "question": text, "correct": right, "wrong": wrong, "alsoAccepted": []}
        if why:
            q["explanation"] = why
        if sign:
            q["image"] = f"assets/signs/{sign}.svg"
        questions.append(q)

    data = {
        "examId": "in_learner_licence",
        "title": "RTO Learner Licence Test",
        "subtitle": "Practice road signs and rules for the LL test",
        "mock": {"size": 15, "passMark": 9, "maxWrong": 7, "secondsPerQuestion": 30, "stopEarly": False},
        "freeQuestionsPerCategory": 8,
        "disclaimer": "This app is not affiliated with, endorsed by, or connected to any government body, the "
                      "Ministry of Road Transport and Highways, Parivahan or any RTO. It is an independent study aid. "
                      "Questions are original and based on public road rules. The real test format varies by state "
                      "(most use 15 questions and 9 correct to pass). For official information visit "
                      "parivahan.gov.in.",
        "categories": cats,
        "questions": questions,
    }
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "questions.json")
    with open(out, "w") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    print(f"wrote {len(questions)} questions ({sum(1 for q in questions if 'image' in q)} with signs)")


if __name__ == "__main__":
    main()
