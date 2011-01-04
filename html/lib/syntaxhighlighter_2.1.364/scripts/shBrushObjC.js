/**
 * SyntaxHighlighter
 * http://alexgorbatchev.com/
 *
 * SyntaxHighlighter is donationware. If you are using it, please donate.
 * http://alexgorbatchev.com/wiki/SyntaxHighlighter:Donate
 *
 * @version
 * 2.1.364 (October 15 2009)
 * 
 * @copyright
 * Copyright (C) 2004-2009 Alex Gorbatchev.
 * Copyright (C) 2010 German Laullon.
 *
 * @license
 * This file is part of SyntaxHighlighter.
 * 
 * SyntaxHighlighter is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * SyntaxHighlighter is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with SyntaxHighlighter.  If not, see <http://www.gnu.org/copyleft/lesser.html>.
 */
SyntaxHighlighter.brushes.ObjC = function()
{
	var keywords =	'abstract assert boolean break byte case catch char class const ' +
	'continue default do double else enum extends ' +
	'false final finally float for goto if implements import ' +
	'instanceof int interface long native new null ' +
	'package private protected public return ' +
	'short static strictfp super switch synchronized this throw throws true ' +
	'transient try void volatile while id synthesize pragma self IBAction IBOutlet property';
	
	this.regexList = [
					  { regex: SyntaxHighlighter.regexLib.singleLineCComments,	css: 'comments' },		// one line comments
					  { regex: /\/\*([^\*][\s\S]*)?\*\//gm,						css: 'comments' },	 	// multiline comments
					  { regex: /\/\*(?!\*\/)\*[\s\S]*?\*\//gm,					css: 'preprocessor' },	// documentation comments
					  { regex: SyntaxHighlighter.regexLib.doubleQuotedString,		css: 'string' },		// strings
					  { regex: SyntaxHighlighter.regexLib.singleQuotedString,		css: 'string' },		// strings
					  { regex: /\b([\d]+(\.[\d]+)?|0x[a-f0-9]+)\b/gi,				css: 'value' },			// numbers
					  { regex: /(\w*):/g,											css: 'color1' },		// 
					  { regex: new RegExp(this.getKeywords(keywords), 'gm'),		css: 'keyword' }		// java keyword
					  ];
	
	this.forHtmlScript({
					   left	: /(&lt;|<)%[@!=]?/g, 
					   right	: /%(&gt;|>)/g 
					   });
};

SyntaxHighlighter.brushes.ObjC.prototype	= new SyntaxHighlighter.Highlighter();
SyntaxHighlighter.brushes.ObjC.aliases		= ['objc'];
