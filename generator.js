const {readFileSync, writeFileSync} = require('fs');
const SEPERATOR = "%%%"
const codeFile = "code.c";
const textFile = "data/labels_test_1.txt";
// const code = readFileSync(codeFile, "utf8").split('\n');
const text = readFileSync(textFile, "utf8").split('\n');

function replaceChar(ch) {
	switch (ch.charCodeAt(0)) {
		case 0xe4: 		// ä
			return 'a';
		case 0xe6: 		// æ
			return 'ae'
		case 0xe9: 		// é
		case 0xea: 		// ê
			return 'e';
		case 0xf6: 		// ö
			return 'o';
		case 0xfc: 		// ü
			return 'u'
		case 0x200a: 	// [hair space] [not actually there]
			return ' '
		case 0x2013: 	// –
		case 0x2014: 	// —
			return '-';
		case 0x2018: 	// ‘
		case 0x2019: 	// ’
			return "'";
		case 0x201c: 	// “
		case 0x201d: 	// ”
			return '"';
		default:
			return 'X';	// idk why
	}
}

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
function findNonAscii(text) {
	let set = new Set();
	for (let i = 0; i < text.length; i++) {
		for (let j = 0; j < text[i].length; j++) {
			let c = text[i].charCodeAt(j)
			if ((c < 32 || c > 126) && (c != 10)) {
				set.add(c)
			}
		}
	}
	for (ch of set) {
		console.log(`${ch.toString(16)}\t${ch}\t${String.fromCharCode(ch)}`);
	}
}
function writeAsciified(text, outfile) {
	for (let i = 0; i < text.length; i++) {
		text[i] = text[i].replace(/[^ -~\n]/g, replaceChar);
	}
	writeFileSync(outfile, text.join('\n'));
}
function strsplice(str, index, chrs2del, replacement) {
	return str.substring(0, index) + replacement + str.substring(index + chrs2del);
}
// function writeAsciified(text, outfile) {
// 	changes = 0;
// 	for (let i = 0; i < text.length; i++) {
// 		for (let j = 0; j < text[i].length; j++) {
// 			let c = text[i].charCodeAt(j)
// 			if ((c < 32 || c > 126) && (c != 10)) {
// 				changes++;
// 				text[i] = strsplice(text[i], j, 1, replaceChar(c));
// 			}
// 		}
// 	}
// 	console.log(changes);
// }
// console.log(getRandomCode(code));
// console.log(getRandomText(text));
// generateData(code, text, "examples_train_1.txt", "labels_train_1.txt", 5000, 0.5);
// findNonAscii(text);
writeAsciified(text, textFile);

