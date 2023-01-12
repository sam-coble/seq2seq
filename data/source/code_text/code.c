/* * * * * * 

JSON parser in C
Sam Coble 
12/2022 
https://github.com/sam-coble/json_c

* * * * * * */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "json.h"


int isjWhitespace (char* str) {
	char* start = str;
	while (*str != '\0') {
		if (!isCharWhitespace(*str))
			return 0;
		str += 1;
	}
	return str - start;
}
int isCharWhitespace (char ch) {
	return 
		ch == ' ' ||
		ch == '\t' ||
		ch == '\r' ||
		ch == '\n';
}
char* firstNonSpace (char* str) {
	while (isCharWhitespace(*str))
		str += 1;
	return str;
}
char* firstEndSpace (char* str) {
	char* start = str;
	while (*str != '\0')
		str += 1;
	while (str > start && isCharWhitespace(*(str - 1)))
		str -= 1;
	return str;
}
json_type getjNodeType (char* str) {
	char* start = firstNonSpace(str);
	char* end = firstEndSpace(start);
	if (start == end)
		return jWHITESPACE;
	char endHolder = *end;
	*end = '\0';
	json_type ret;
	if (isjString(start)) {
		ret = jSTRING;
	} else if (isjNumber(start)) {
		ret = jNUMBER;
	} else if (isjArray(start)) {
		ret = jARRAY;
	} else if (isjObject(start)) {
		ret = jOBJECT;
	} else if (isjWhitespace(start)) {
		ret = jWHITESPACE;
	} else if (isjTrue(start)) {
		ret = jTRUE;
	} else if (isjFalse(start)) {
		ret = jFALSE;
	} else if (isjNull(start)) {
		ret = jNULL;
	} else {
		ret = jERROR;
	}
	*end = endHolder;
	return ret;
}
jNode* getjNode (char* str) {
	// printf("creating node\n");
	jNode* node = malloc(sizeof(*node));
	char* start = firstNonSpace(str);
	char* end = firstEndSpace(start);
	node->type = getjNodeType(str);
	node->contents = NULL;
	node->datalen = end - start;
	node->rawdata = malloc(sizeof(*node->rawdata) * (node->datalen + 1));
	for (int i = 0; i < node->datalen; i++)
		node->rawdata[i] = start[i];
	return node;
}
void freejNode (jNode* node) {
	if (node == NULL)
		return;
	*node->contents = NULL; // node->contents->holder
	switch (node->type) {
		case jSTRING:
			freejString((jString*)node->contents);
			break;
		case jNUMBER:
			freejNumber((jNumber*)node->contents);
			break;
		case jARRAY:
			freejArray((jArray*)node->contents);
			break;
		case jOBJECT:
			freejObject((jObject*)node->contents);
			break;
		default:
			break;
	}
	free (node->rawdata);
	free (node);
}
int isjTrue (char* str) {
	return (*str++ == 't' &&
			*str++ == 'r' &&
			*str++ == 'u' &&
			*str++ == 'e' &&
			*str == '\0') ? 4 : 0;
}
int isjFalse (char* str) {
	return (*str++ == 'f' &&
			*str++ == 'a' &&
			*str++ == 'l' &&
			*str++ == 's' &&
			*str++ == 'e' &&
			*str == '\0') ? 5 : 0;
}
int isjNull (char* str) {
	return (*str++ == 'n' &&
		*str++ == 'u' &&
		*str++ == 'l' &&
		*str++ == 'l' &&
		*str == '\0') ? 4 : 0;
}
// /-?(0|[1-9]\d*)(\.\d+)?([eE][\+\-]?\d+)?/
int isjNumber (char* str) {
	char* start = str;
	if (*str == '-')
		str += 1;

	if (*str == '0') {
		str += 1;
	} else if (*str >= '1' && *str <= '9') {
		while (*str >= '1' && *str <= '9')
			str += 1;
	} else { // number must contian at least one digit
		return 0;
	}

	if (*str == '.') {
		str += 1;
		if (*str < '0' || *str > '9') // at least one digit must follow '.'
			return 0;
		while (*str >= '0' && *str <= '9')
			str += 1;
	}

	if (*str == 'e' || *str == 'E') {
		str +=1;
		if (*str == '+' || *str == '-')
			str += 1;
		if (*str < '0' || *str > '9') // at least one digit must follow (e|e\+|e-)
			return 0;
		while (*str >= '0' && *str <= '9')
			str += 1;
	}

	if (*str == '\0')
		return str - start;

	return 0;
}
// /"(.|\\["\\/bfnrt])*"/
int isjString (char* str) {
	char* start = str;
	if (*str != '"')
		return 0;
	str += 1;
	while (*str != '"') {
		if (*str == '\\') {
			str += 1;
			if (*str == 'u') {
				for (int i = 0; i < 4; i++) {
					str += 1;
					if ((*str < '0' || *str > '9') &&
						(*str < 'a' || *str > 'f')) {
						return 0;
					}
				}
			} else if (
				*str != '"' &&
				*str != '\\' && 
				*str != '/' &&
				*str != 'b' &&
				*str != 'f' &&
				*str != 'n' &&
				*str != 'r' &&
				*str != 't') {
				return 0;
			}
		}
		else if (*str == '\0') {
			return 0;
		}
		str += 1;
	}

	str += 1;
	if (*str == '\0')
		return str - start;
	return 0;
}
int isjArray (char* str) {
	char* start = str;
	if (*str != '[')
		return 0;
	while (*str != ']') {
		int inString = 0, sbCount = 0, cbCount = 0; // " [
		char* endValue = str + 1;
		while (*endValue != '\0') {
			if (*endValue == '"')
				inString = !inString;
			else if (*endValue == '[' && !inString)
				sbCount++;
			else if (*endValue == ']' && sbCount > 0 && !inString)
				sbCount--;
			else if (*endValue == ']' && sbCount == 0 && !inString)
				break;
			else if (*endValue == '<' && !inString)
				cbCount++;
			else if (*endValue == '>' && !inString)
				cbCount--;
			else if (*endValue == ',' && !sbCount && !cbCount && !inString)
				break;
			endValue += 1;
		}
		if (*endValue == '\0')
			return 0;

		char endHolder = *endValue;
		*endValue = '\0';
		json_type elementType = getjNodeType(str + 1);
		*endValue = endHolder;

		if (elementType == jERROR)
			return 0;

		if (elementType == jWHITESPACE &&
			(*str != '[' || *endValue != ']'))
			return 0;
		
		str = endValue;
	}

	if (*++str == '\0')
		return str - start;
	return 0;
}
int isjObject (char* str) {
	char* start = str;
	if (*str != '<')
		return 0;
	while (*str != '>') {
		int inString = 0, cbCount = 0, sbCount = 0; // " < [
		char* endValue = str + 1;
		while (*endValue != '\0') {
			if (*endValue == '"')
				inString = !inString;
			else if (*endValue == '<' && !inString)
				cbCount++;
			else if (*endValue == '>' && cbCount > 0 && !inString)
				cbCount--;
			else if (*endValue == '>' && !cbCount && !inString)
				break;
			else if (*endValue == ':' && !cbCount && !inString)
				break;
			endValue += 1;
		}
		if (*endValue == '\0')
			return 0;

		char endHolder = *endValue;
		*endValue = '\0';
		json_type elementType = getjNodeType(str + 1);
		*endValue = endHolder;

		if (elementType == jWHITESPACE &&
			*str == '<' && 
			*endValue == '>')
			return endValue - start;

		if (elementType != jSTRING ||
			*endValue == '>')
			return 0;

		str = endValue;

		inString = 0, cbCount = 0, sbCount = 0;
		endValue = str + 1;
		while (*endValue != '\0') {
			if (*endValue == '"')
				inString = !inString;
			else if (*endValue == '<' && !inString)
				cbCount++;
			else if (*endValue == '>' && cbCount > 0 && !inString)
				cbCount--;
			else if (*endValue == '>' && cbCount == 0 && !inString)
				break;
			else if (*endValue == '[' && !inString)
				sbCount++;
			else if (*endValue == ']' && !inString)
				sbCount--;
			else if (*endValue == ',' && !cbCount && !sbCount && !inString)
				break;
			endValue += 1;
		}
		if (*endValue == '\0')
			return 0;

		endHolder = *endValue;
		*endValue = '\0';
		elementType = getjNodeType(str + 1);
		*endValue = endHolder;

		if (elementType == jWHITESPACE ||
			elementType == jERROR)
			return 0;

		str = endValue;
	}

	if (*++str == '\0')
		return str - start;
	return 0;
}
jString* getjString(jNode* node) {
	if (node->type != jSTRING)
		return NULL;
	if (node->contents != NULL)
		return (jString*)node->contents;
	jString* string = malloc(sizeof(*string));
	node->contents = (void**)string;
	string->holder = node;
	string->length = node->datalen - 2;
	string->chars = malloc(sizeof(*string->chars) * (string->length + 1));
	for (int i = 0; i < node->datalen - 2; i++)
		string->chars[i] = node->rawdata[i + 1];
	string->chars[string->length] = '\0';
	return string;
}
void freejString(jString* string) {
	if (string->holder != NULL) {
		freejNode(string->holder);
		return;
	}
	free(string->chars);
	free(string);
}

int containsDecimalOrExponent (char* str, int len) {
	for (int i = 0; i < len; i++)
		if (str[i] == '.' || str[i] == 'e' || str[i] == 'E')
			return 1;
	return 0;
}
jNumber* getjNumber(jNode* node) {
	if (node->type != jNUMBER)
		return NULL;
	if (node->contents != NULL)
		return (jNumber*)node->contents;
	jNumber* number = malloc(sizeof(*number));
	node->contents = (void**)number;
	number->holder = node;
	if (containsDecimalOrExponent(node->rawdata, node->datalen)) {
		number->isInt = 0;
		number->dvalue = atof(node->rawdata);
		number->ivalue = (int)number->dvalue;
	} else {
		number->isInt = 1;
		number->ivalue = atoi(node->rawdata);
		number->dvalue = (double)number->ivalue;
	}
	return number;
}
void freejNumber(jNumber* number) {
	if (number->holder != NULL) {
		freejNode(number->holder);
		return;
	}
	free(number);
}
char* findNextComma (char* start, char* end) {
	int inString = 0, cbCount = 0, sbCount = 0;
	for (char* cur = start; cur < end; cur += 1) {
		if (*cur == '\0')
			return NULL;
		else if (*cur == '"')
			inString = !inString;
		else if (*cur == '[' && !inString)
			sbCount++;
		else if (*cur == ']' && !inString)
			sbCount--;
		else if (*cur == '<' && !inString)
			cbCount++;
		else if (*cur == '>' && !inString)
			cbCount--;
		else if (*cur == ',' && !inString && !cbCount && !sbCount)
			return cur;
	}
	return NULL;
}
jArray* getjArray(jNode* node) {
	if (node->type != jARRAY)
		return NULL;
	// printf("getting array\n");
	if (node->contents != NULL)
		return (jArray*)node->contents;
	jArray* array = malloc(sizeof(*array));
	node->contents = (void**)array;
	array->holder = node;
	int commaCount = 0;
	char* cur = findNextComma(node->rawdata + 1, node->rawdata + node->datalen);
	while (cur != NULL) {
		commaCount++;
		cur = findNextComma(cur + 1, node->rawdata + node->datalen);
	}

	if (!commaCount && *firstNonSpace(node->rawdata + 1) == ']')
		array->size = 0;
	else
		array->size = commaCount + 1;
	array->elements = malloc(sizeof(*array->elements) * array->size);

	int i = 0;
	char* prev = node->rawdata + 1;
	cur = findNextComma(prev, node->rawdata + node->datalen);
	while (cur != NULL) {
		*cur = '\0';
		array->elements[i++] = getjNode(prev);
		*cur = ',';
		prev = cur + 1;
		cur = findNextComma(prev, node->rawdata + node->datalen);
	}
	// printf("prev=%c\n", *prev);
	if (array->size > 0) {
		*(node->rawdata + node->datalen - 1) = '\0';
		array->elements[i] = getjNode(prev);
		*(node->rawdata + node->datalen - 1) = ']';
	}
	
	
	// printf("array size=%d\n", array->size);
	// printf("array[0]=%p\n", array->elements[0]);
	return array;
}
void freejArray(jArray* array) {
	if (array->holder != NULL) {
		freejNode(array->holder);
		return;
	}
	for (int i = 0; i < array->size; i++)
		freejNode(array->elements[i]);
	free(array->elements);
	free(array);
}
char* findNextColon (char* start, char* end) {
	int inString = 0, cbCount = 0, sbCount = 0;
	for (char* cur = start; cur < end; cur += 1) {
		if (*cur == '\0')
			return NULL;
		else if (*cur == '"')
			inString = !inString;
		else if (*cur == '[' && !inString)
			sbCount++;
		else if (*cur == ']' && !inString)
			sbCount--;
		else if (*cur == '<' && !inString)
			cbCount++;
		else if (*cur == '>' && !inString)
			cbCount--;
		else if (*cur == ':' && !inString && !cbCount && !sbCount)
			return cur;
	}
	return NULL;
}
jObject* getjObject(jNode* node) {
	if (node->type != jOBJECT)
		return NULL;
	if (node->contents != NULL)
		return (jObject*)node->contents;
	jObject* object = malloc(sizeof(*object));
	node->contents = (void**)object;
	object->holder = node;
	int colonCount = 0;
	char* cur = findNextColon(node->rawdata + 1, node->rawdata + node->datalen);
	while (cur != NULL) {
		colonCount++;
		cur = findNextColon(cur + 1, node->rawdata + node->datalen);
	}

	object->size = colonCount;
	object->keys = malloc(sizeof(*object->keys) * object->size);
	object->values = malloc(sizeof(*object->values) * object->size);

	int i = 0;
	char* prev = node->rawdata + 1;
	cur = findNextColon(prev, node->rawdata + node->datalen);
	while (cur != NULL) {
		*cur = '\0';
		object->keys[i] = getjNode(prev);
		*cur = ':';
		prev = cur + 1;
		cur = findNextComma(prev, node->rawdata + node->datalen);
		if (cur == NULL) {
			*(node->rawdata + node->datalen - 1) = '\0';
			object->values[i++] = getjNode(prev);
			*(node->rawdata + node->datalen - 1) = '>';
			break;
		} else {
			*cur = '\0';
			object->values[i++] = getjNode(prev);
			*cur = ',';
			prev = cur + 1;
			cur = findNextColon(prev, node->rawdata + node->datalen);
		}
		
	}

	return object;
}
void freejObject(jObject* object) {
	if (object->holder != NULL) {
		freejNode(object->holder);
		return;
	}
	for (int i = 0; i < object->size; i++) {
		freejNode(object->keys[i]);
		freejNode(object->values[i]);
	}
	free(object->keys);
	free(object->values);
	free(object);
}
void printTabs(int tabs) {
	for (int i = 0; i < tabs; i++)
		printf("  ");
}
void printjString(jString* string, int tabs) {
	printTabs(0);
	// printTabs(tabs);
	printf("\"%s\"", string->chars);
}
void printjNumber(jNumber* number, int tabs) {
	printTabs(0);
	// printTabs(tabs);
	if (number->isInt)
		printf("%d", number->ivalue);
	else
		printf("%f", number->dvalue);
}
void printjArray(jArray* array, int tabs) {
	// printTabs(tabs);
	if (array->size == 0) {
		printf("[]");
		return;
	}
	printf("[\n");
	for (int i = 0; i < array->size; i++) {
		printTabs(tabs + 1);
		printjNode(array->elements[i], tabs + 1);
		if (i < array->size - 1)
			printf(",");
		printf("\n");
	}
	printTabs(tabs);
	printf("]");
}
void printjObject(jObject* object, int tabs) {
	// printTabs(tabs);
	if (object->size == 0) {
		printf("{}");
		return;
	}
	printf("{\n");
	for (int i = 0; i < object->size; i++) {
		printTabs(tabs + 1);
		printjNode(object->keys[i], tabs + 1);
		printf(": ");
		printjNode(object->values[i], tabs + 1);
		if (i < object->size - 1)
			printf(",");
		printf("\n");
	}

	printTabs(tabs);
	printf("}");
}
void printjNode(jNode* node, int tabs) {
	// printf("printing\n");
	// printf("type= %d\n", node->type);
	switch (node->type) {
		case jSTRING: {
			printjString(getjString(node), tabs);
			break;
		} case jNUMBER: {
			printjNumber(getjNumber(node), tabs);
			break;
		} case jARRAY: {
			printjArray(getjArray(node), tabs);
			break;
		} case jOBJECT: {
			printjObject(getjObject(node), tabs);
			break;
		} default: {
			printf("Could not parse.\n");
			break;
		}
	}
}
