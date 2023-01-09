const {readFileSync, writeFileSync} = require('fs');
const SEPERATOR = "%%%"
const codeFile = "code.c";
const textFile = "text.txt";
const code = readFileSync(codeFile, "utf8").split('\n');
const text = readFileSync(textFile, "utf8").split('\n');

function getRandomLine(code) {
	let rand = Math.floor(Math.random() * code.length);
	for (let i = rand; i != rand - 1; i = (i + 1) % code.length) {
		if (code[i].trim().slice(-1) == ';') {
			return code[i].trim();
		}
	}
	return "this.isNotCode([nothingWas[found]]);";
}
function getRandomBlock(code) {
	let rand = Math.floor(Math.random() * code.length);
	for (let i = rand; i != rand - 1; i = (i + 1) % code.length) {
		if (code[i].split('{').length - code[i].split('}').length > 0) {
			rand = i;
			break;
		}
	}
	let spaces = code[rand].length - code[rand].trimStart().length;
	let bracketCount = code[rand].split('{').length - code[rand].split('}').length;
	let i = rand + 1;
	while (bracketCount > 0 && i < code.length) {
		bracketCount += code[i].split('{').length - code[i].split('}').length;
		i++;
	}
	return code.slice(rand, i).map(e => e.slice(spaces)).join('\n');
}
function getRandomBlockInterior(code) {
	let rand = Math.floor(Math.random() * code.length);
	for (let i = rand; i != rand - 1; i = (i + 1) % code.length) {
		if (code[i].split('{').length - code[i].split('}').length > 0) {
			rand = i;
			break;
		}
	}
	let spaces = code[rand + 1].length - code[rand + 1].trimStart().length;
	let bracketCount = code[rand].split('{').length - code[rand].split('}').length;
	let i = rand + 1;
	while (bracketCount > 0 && i < code.length) {
		bracketCount += code[i].split('{').length - code[i].split('}').length;
		i++;
	}
	return code.slice(rand + 1, i - 1).map(e => e.slice(spaces)).join('\n');
}
function getRandomCode(code) {
	return Math.random() < 0.4 ? getRandomBlock(code) : getRandomBlockInterior(code);
}
function getRandomText(text) {
	let rand = Math.floor(Math.random() * text.length);
	return text.slice(rand, rand + 1 + Math.floor(Math.random() * 4)).join('\n');
}
function generateData(code, text, xfile, yfile, n, p) {
	p = p ?? 0.5;
	x = [];
	y = [];
	for (let i = 0; i < n; i++) {
		if (Math.random() < p) {
			y.push(0);
			x.push(getRandomCode(code));
		} else {
			y.push(1);
			x.push(getRandomText(text));
		}
	}
	writeFileSync(xfile, x.join(`\n${SEPERATOR}\n`));
	writeFileSync(yfile, y.join(`\n`));

}
// console.log(getRandomCode(code));
// console.log(getRandomText(text));
generateData(code, text, "examples1.txt", "labels1.txt", 1000, 0.5);


