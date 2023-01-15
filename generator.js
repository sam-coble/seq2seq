const {readFileSync, writeFileSync} = require('fs');
const SEPERATOR = "%%%"
// const codeFile = "code.c";
// const textFile = "data/labels_test_1.txt";
// const textFile1 = "data/source/lang/english.txt";
// const textFile2 = "data/source/lang/spanish.txt";
// const code = readFileSync(codeFile, "utf8").split('\n');
// const text1 = readFileSync(textFile1, "utf8").split('\n');
// const text2 = readFileSync(textFile2, "utf8").split('\n');

function replaceChar(ch) {
	switch (ch.charCodeAt(0)) {
		case 0x0d: 		// carrige feed
			return '';
		case 0xba: 		// º
			return '';
		case 0xc1: 		// Á 
			return 'A';
		case 0xe1: 		// á
		case 0xe2: 		// â
		case 0xe3: 		// ã
		case 0xe4: 		// ä
			return 'a';
		case 0xe6: 		// æ
			return 'ae'
		case 0xe8: 		// è
		case 0xe9: 		// é
		case 0xea: 		// ê
			return 'e';
		case 0xed: 		// í
			return 'i';
		case 0xf1: 		// ñ
			return 'n';
		case 0xf3: 		// ó
		case 0xf6: 		// ö
			return 'o';
		case 0xfa: 		// ú
		case 0xf9: 		// ù
		case 0xfc: 		// ü
			return 'u'
		case 0x200a: 	// [hair space] [not actually there]
			return ' ';
		case 0xad: 		// soft hypen
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
function cleanFrequencyList(text, file) {
	for (let i = 0; i < text.length; i++) {
		text[i] = text[i].slice(0, text[i].indexOf('\t'));
	}
	writeFileSync(file, text.join('\n'));
}
function sampleWords(text, n, outfile) {
	let ret = [];
	for (let i = 0; i < n; i++) {
		let r = Math.floor(Math.exp(Math.random() * Math.log(text.length + 1)));
		ret.push(text[r]);
	}
	writeFileSync(outfile, ret.join('\n'));
}

function generateTrainAndTestUniform(texts, trexf, teexf, trlaf, telaf, n, p) {
	p = Math.round(1/p);
	trex = [];
	trla = [];
	teex = [];
	tela = [];
	for (let i = 0; i < n; i++) {
		let text = Math.floor(Math.random() * texts.length);
		let r = Math.floor(Math.random() * texts[text].length);
		if (r % p == 0) {
			teex.push(texts[text][r]);
			tela.push(text);
		} else {
			trex.push(texts[text][r]);
			trla.push(text);
		}
	}
	writeFileSync(trexf, trex.join(`\n${SEPERATOR}\n`));
	writeFileSync(trlaf, trla.join('\n'));
	writeFileSync(teexf, teex.join(`\n${SEPERATOR}\n`));
	writeFileSync(telaf, tela.join('\n'));
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
// cleanFrequencyList(text, textFile)
// writeAsciified(text, textFile);
// generateTrainAndTestUniform([text1, text2], "data/mixed/lang/examples_train_1.txt", "data/mixed/lang/examples_test_1.txt",
// 		"data/mixed/lang/labels_train_1.txt", "data/mixed/lang/labels_test_1.txt", 40000, 0.2);



function findNonCharacters(text) {
	let set = new Set();
	for (let i = 0; i < text.length; i++) {
		for (let j = 0; j < text[i].length; j++) {
			let c = text[i].charCodeAt(j);
			if (c < 97 || c > 123) {
				set.add(c);
			}
		}
	}
	for (ch of set) {
		console.log(`${ch.toString(16)}\t${ch}\t${String.fromCharCode(ch)}`);
	}
}
function sampleWordsTrainTest(text, trainFile, testFile, n, p) {
	p = Math.round(1/p);
	train = [];
	test = [];
	for (let i = 0; i < n; i++) {
		let r = Math.floor(Math.random() * text.length);
		if (r % p == 0) {
			test.push(text[r]);
		} else {
			train.push(text[r]);
		}
	}
	writeFileSync(trainFile, train.join('\n'));
	writeFileSync(testFile, test.join('\n'));
}

const filename = "data/source/words.txt"
const text = readFileSync(filename, "utf8").split('\n');
sampleWordsTrainTest(text, 'data/mixed/words_train_1.txt', 'data/mixed/words_test_1.txt',
		40000, 0.2);



