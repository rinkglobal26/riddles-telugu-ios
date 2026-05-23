const fs = require("fs");

const riddles = JSON.parse(fs.readFileSync("TeluguRiddles/Resources/riddles.json", "utf8"));
const ids = new Set(riddles.map((riddle) => riddle.id));
const missing = riddles.filter((riddle) =>
  !riddle.question ||
  !riddle.answer ||
  !riddle.hint ||
  !riddle.category ||
  !riddle.englishQuestion ||
  !riddle.englishAnswer ||
  !riddle.englishHint ||
  !riddle.englishCategory
);
const duplicateQuestions = riddles
  .map((riddle) => riddle.question)
  .filter((question, index, all) => all.indexOf(question) !== index);
const categoryCounts = riddles.reduce((counts, riddle) => {
  counts[riddle.category] = (counts[riddle.category] || 0) + 1;
  return counts;
}, {});

console.log(`Riddles: ${riddles.length}`);
console.log(`Unique IDs: ${ids.size}`);
console.log(`Missing required fields: ${missing.length}`);
console.log(`Duplicate question text: ${new Set(duplicateQuestions).size}`);
console.log("Categories:");
for (const [category, count] of Object.entries(categoryCounts).sort()) {
  console.log(`- ${category}: ${count}`);
}

if (riddles.length < 1000 || ids.size !== riddles.length || missing.length > 0 || duplicateQuestions.length > 0) {
  process.exitCode = 1;
}
