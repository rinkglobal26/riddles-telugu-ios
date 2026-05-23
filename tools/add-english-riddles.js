const fs = require("fs");
const path = require("path");

const filePath = path.join(__dirname, "..", "TeluguRiddles", "Resources", "riddles.json");

const categories = {
  "ఆధునికం": "Modern",
  "ఇల్లు": "Home",
  "కూరగాయలు": "Vegetables",
  "జంతువులు": "Animals",
  "పండుగలు": "Festivals",
  "పండ్లు": "Fruits",
  "పనిముట్లు": "Tools",
  "పాఠశాల": "School",
  "ప్రకృతి": "Nature",
  "ప్రయాణం": "Travel",
  "వంటగది": "Kitchen",
  "శరీరం": "Body",
  "సంగీతం": "Music",
  "సమయం": "Time"
};

const difficulties = {
  "సులువు": "Easy",
  "మధ్యస్థం": "Medium",
  "చురుకు": "Quick"
};

const answers = {
  "దీపం": ["Lamp", "It gives light and chases away darkness."],
  "విసనకర్ర": ["Hand fan", "It moves by hand and gives cool air."],
  "గడియారం": ["Clock", "It tells time without walking anywhere."],
  "తాళం": ["Lock", "It keeps a door or secret safely closed."],
  "తాళంచెవి": ["Key", "It opens the right lock when turned."],
  "అద్దం": ["Mirror", "It shows whoever stands before it."],
  "దిండు": ["Pillow", "It gives the head a soft place to rest."],
  "కుర్చీ": ["Chair", "It has legs but does not walk."],
  "మెజ్జ": ["Table", "It quietly holds books, plates, and many other things."],
  "తలుపు": ["Door", "It opens for welcome and closes for safety."],
  "కిటికీ": ["Window", "It lets light, air, and the outside view into a room."],
  "చీపురు": ["Broom", "It sweeps dust away from the floor."],
  "బకెట్": ["Bucket", "It carries water in its belly."],
  "సబ్బు": ["Soap", "It makes foam and cleans dirt away."],
  "పుస్తకం": ["Book", "It carries many worlds inside its pages."],
  "పెన్సిల్": ["Pencil", "It grows shorter as it writes."],
  "రబ్బరు": ["Eraser", "It removes pencil mistakes."],
  "బ్యాగు": ["Bag", "It carries books and supplies on your shoulder."],
  "బ్లాక్ బోర్డు": ["Blackboard", "It becomes full of lessons when chalk touches it."],
  "చాక్": ["Chalk", "It writes white marks on a dark board."],
  "సూర్యుడు": ["Sun", "It wakes the world with light and heat."],
  "చంద్రుడు": ["Moon", "It changes shape in the night sky."],
  "నక్షత్రం": ["Star", "It twinkles far away in the night sky."],
  "మేఘం": ["Cloud", "It floats in the sky and may bring rain."],
  "వాన": ["Rain", "It falls from the sky as drops of water."],
  "గాలి": ["Air", "You cannot see it, but you can feel it."],
  "నది": ["River", "It flows from the hills toward the sea."],
  "సముద్రం": ["Sea", "It is full of water, waves, and salt."],
  "కొండ": ["Hill", "It rises high from the land."],
  "చెట్టు": ["Tree", "Its roots are in the ground and its branches reach upward."],
  "ఆకు": ["Leaf", "It is a small green part of a tree."],
  "పువ్వు": ["Flower", "It shares color and fragrance."],
  "మామిడి పండు": ["Mango", "It is a sweet summer fruit."],
  "అరటి పండు": ["Banana", "It has a yellow peel and a soft inside."],
  "ద్రాక్ష": ["Grapes", "They grow in bunches as small sweet fruits."],
  "దానిమ్మ": ["Pomegranate", "It hides red jewel-like seeds inside."],
  "పుచ్చకాయ": ["Watermelon", "It is green outside and cool red inside."],
  "కొబ్బరి": ["Coconut", "It has a hard shell and sweet water inside."],
  "బత్తాయి": ["Sweet lime", "It has juicy slices with a sweet-sour taste."],
  "సీతాఫలం": ["Custard apple", "It has soft sweet pulp and black seeds."],
  "టమాటా": ["Tomato", "It turns red and adds flavor to food."],
  "ఉల్లిపాయ": ["Onion", "It has many layers and can bring tears."],
  "మిరపకాయ": ["Chili", "It is small but brings heat to the tongue."],
  "వంకాయ": ["Eggplant", "It often wears a purple coat."],
  "దోసకాయ": ["Cucumber", "It is cool, green, and crunchy."],
  "క్యారెట్": ["Carrot", "It grows underground and is orange."],
  "బంగాళాదుంప": ["Potato", "It grows under the soil and can be cooked many ways."],
  "బీరకాయ": ["Ridge gourd", "It is a long green vegetable."],
  "ఆవు": ["Cow", "It eats grass and gives milk."],
  "కుక్క": ["Dog", "It barks and guards the home."],
  "పిల్లి": ["Cat", "It walks softly and says meow."],
  "గుర్రం": ["Horse", "It is known for running fast."],
  "ఏనుగు": ["Elephant", "It is huge and has a long trunk."],
  "కోతి": ["Monkey", "It jumps from tree to tree."],
  "చేప": ["Fish", "It lives and swims in water."],
  "పక్షి": ["Bird", "It has wings and flies in the sky."],
  "తేనెటీగ": ["Honeybee", "It visits flowers and makes honey."],
  "చీమ": ["Ant", "It is tiny but carries heavy loads in a line."],
  "కన్ను": ["Eye", "It lets you see the world."],
  "చెవి": ["Ear", "It hears sounds, songs, and words."],
  "ముక్కు": ["Nose", "It smells and helps you breathe."],
  "నోరు": ["Mouth", "It is the doorway for food, words, and smiles."],
  "చేయి": ["Hand", "It helps you hold, write, give, and work."],
  "కాలు": ["Leg", "It helps you walk, run, and travel."],
  "గుండె": ["Heart", "It beats inside and keeps life moving."],
  "నాలుక": ["Tongue", "It tastes food and helps form words."],
  "వంటగిన్నె": ["Cooking pot", "It sits on heat and helps make food."],
  "చంచా": ["Ladle", "It stirs and serves food."],
  "పళ్లెం": ["Plate", "It holds rice, curry, and a meal."],
  "చెంచా": ["Spoon", "It carries a small bite from plate to mouth."],
  "ఉప్పు": ["Salt", "Tiny grains that balance flavor."],
  "చెక్కెర": ["Sugar", "White grains that make things sweet."],
  "మిరియాలు": ["Pepper", "Small dark seeds with a warm spicy bite."],
  "పాలు": ["Milk", "A white drink that can boil and rise."],
  "బియ్యం": ["Rice grains", "Small white grains that become cooked rice."],
  "అన్నం": ["Cooked rice", "A main food at many Telugu meals."],
  "బస్సు": ["Bus", "It carries many people and stops along the road."],
  "రైలు": ["Train", "It runs on tracks with carriages behind it."],
  "సైకిల్": ["Bicycle", "It has two wheels and moves by pedaling."],
  "కారు": ["Car", "A four-wheeled room that moves on roads."],
  "విమానం": ["Airplane", "It flies above clouds and crosses countries."],
  "పడవ": ["Boat", "It travels on water."],
  "గొడుగు": ["Umbrella", "It opens like a small roof against rain or sun."],
  "చెప్పు": ["Sandal", "It protects your foot while walking."],
  "మొబైల్ ఫోన్": ["Mobile phone", "A small world you can hold in your hand."],
  "టెలివిజన్": ["Television", "It shows pictures and sound from far away."],
  "రిమోట్": ["Remote control", "It changes the screen from across the room."],
  "కంప్యూటర్": ["Computer", "It helps with work, learning, and play."],
  "కీబోర్డు": ["Keyboard", "Its buttons turn finger taps into words."],
  "మౌస్": ["Mouse", "It moves the pointer and clicks on a computer."],
  "ఫ్రిజ్": ["Fridge", "It keeps food cold inside."],
  "ఫ్యాన్": ["Fan", "It spins and gives air."],
  "లైట్ బల్బ్": ["Light bulb", "It gives light when switched on."],
  "క్యాలెండర్": ["Calendar", "It shows days, months, and dates."],
  "సంక్రాంతి": ["Sankranti", "A harvest festival with rangoli and kites."],
  "దీపావళి": ["Diwali", "A festival of lights and sweets."],
  "ఉగాది": ["Ugadi", "The Telugu New Year."],
  "వినాయక చవితి": ["Vinayaka Chavithi", "A festival for Ganesha with modaks and clay idols."],
  "రాఖీ": ["Rakhi", "A thread that celebrates sibling love."],
  "ముగ్గు": ["Rangoli", "Art drawn at the doorstep with powder."],
  "గాలిపటం": ["Kite", "It dances in the sky while held by a string."],
  "డప్పు": ["Dappu drum", "It is struck to make a loud festive beat."],
  "వీణ": ["Veena", "A string instrument with a sweet classical sound."],
  "తాళం బిళ్ళలు": ["Cymbals", "Two small pieces that make rhythm together."],
  "పాట": ["Song", "Words become music when sung."],
  "నాట్యం": ["Dance", "The body speaks through rhythm."],
  "కత్తెర": ["Scissors", "Two blades work together to cut."],
  "సుత్తి": ["Hammer", "It drives nails by striking."],
  "మేకుపట్టి": ["Pliers", "It grips with metal jaws."],
  "సూది": ["Needle", "It has a small eye and stitches cloth."],
  "దారం": ["Thread", "It joins cloth when guided by a needle."],
  "మెట్లు": ["Stairs", "They take you up or down one step at a time."]
};

const templates = [
  (item) => `I do not speak, but here is my clue: ${item.hint} What am I?`,
  (item) => `${item.hint} Everyone at home can recognize me. Who am I?`,
  (item) => `${item.hint} When you see me, my job is easy to guess. What is it?`,
  (item) => `Guess my name without hearing it: ${item.hint} Who am I?`,
  (item) => `A quick riddle for the family: ${item.hint} What is the answer?`,
  (item) => `My clue is simple: ${item.hint} Can you guess me?`,
  (item) => `You may see me often, but I am hidden in this clue: ${item.hint} Who am I?`,
  (item) => `A riddle to make kids smile: ${item.hint} What could it be?`,
  (item) => `An old-style riddle in new words: ${item.hint} What is the answer?`,
  (item) => `Imagine this: ${item.hint} Tell me my name.`
];

const riddles = JSON.parse(fs.readFileSync(filePath, "utf8"));

const augmented = riddles.map((riddle, index) => {
  const answer = answers[riddle.answer];
  if (!answer) {
    throw new Error(`Missing English answer map for ${riddle.answer}`);
  }

  const item = {
    answer: answer[0],
    hint: answer[1]
  };

  return {
    ...riddle,
    englishCategory: categories[riddle.category] || riddle.category,
    englishDifficulty: difficulties[riddle.difficulty] || riddle.difficulty,
    englishQuestion: templates[index % templates.length](item),
    englishAnswer: item.answer,
    englishHint: item.hint
  };
});

fs.writeFileSync(filePath, `${JSON.stringify(augmented, null, 2)}\n`, "utf8");
console.log(`Added English fields to ${augmented.length} riddles at ${filePath}`);
