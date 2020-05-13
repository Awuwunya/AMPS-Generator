using System;
using System.Text.RegularExpressions;

namespace AMPS_Generator {
	internal struct AssemblerInfo {
		internal string ResultPCRelative;

		internal static AssemblerInfo ASM68K = new AssemblerInfo() {
			RSAlign = "\t\trs.w 0", RSSet = "rsset",
			RSB = "rs.b", RSW = "rs.w", RSL = "rs.l", RSEq = "__rs",
			LongAddress = "", LongAddressWithTab = "\t", RSEven = "rs.w 0",
			MacroArgPrefix = "\\", MoveqFix = "$FFFFFF00|", 
			MoveqFix2 = "$FFFFFF", Xor = "^", Mod = "%",
			Set = "=", Equ = "equ", Endr = "endr", TempLabel = "\\@",
			Warning = "inform 1,", Fatal = "inform 3,", ASTab = "",
			RaiseErrorCheck = "def(RaiseError)", ASM68KTab = "\t",
			DynamicLabelStart = "\\", DynamicLabelEnd = "",

			ProcessArgCheck = (comp, arg, mode, extra, comment) => {
				return $"\t{extra}if narg{comp + comment}\n";
			},

			ProcessPCRelative = (label, exp, comment) => {
				Program.Assembler.ResultPCRelative = exp;
				return "";
			}, ResultPCRelative = "<unset>", Name = "ASM68K",
		};

		internal static AssemblerInfo AS = new AssemblerInfo() {
			RSAlign = "\tif 1&(*)\n\t\tds.b 1\t\t; even's are broke in 64-bit values?\n\tendif\t\t\t; align data",
			RSB = "ds.b", RSW = "ds.w", RSL = "ds.l", RSEq = "*", RSSet = "phase",
			LongAddress = ".l", LongAddressWithTab = ".l", Xor = "!", Mod = "#",
			MacroArgPrefix = "", MoveqFix = "", RSEven = "even",
			Set = ":=", Equ = "=", Endr = "endm", TempLabel = "",
			DynamicLabelStart = "{\"", DynamicLabelEnd = "\"}",
			Warning = "warning ", Fatal = "fatal ", ASM68KTab = "",
			RaiseErrorCheck = "isAMPS\t", MoveqFix2 = "$", ASTab = "\t",

			ProcessArgCheck = (comp, arg, mode, extra, comment) => {
				return $"\t{extra}if \"{arg}\"{mode}\"\"{comment}\n";
			},

			ProcessPCRelative = (label, exp, comment) => {
				Program.Assembler.ResultPCRelative = label;
				return $"{label} =\t{exp + comment}\n";
			}, ResultPCRelative = "<unset>", Name = "AS",
		};

		internal string ASM68KTab { get; private set; }
		internal string ASTab { get; private set; }
		internal string RSAlign { get; private set; }
		internal string RSEven { get; private set; }
		internal string RSSet { get; private set; }
		internal string RSEq { get; private set; }
		internal string RSB { get; private set; }
		internal string RSW { get; private set; }
		internal string RSL { get; private set; }
		internal string Xor { get; private set; }
		internal string Mod { get; private set; }
		internal string Set { get; private set; }
		internal string Equ { get; private set; }
		internal string Endr { get; private set; }
		internal string Fatal { get; private set; }
		internal string Warning { get; private set; }
		internal string MoveqFix { get; private set; }
		internal string MoveqFix2 { get; private set; }
		internal string TempLabel { get; private set; }
		internal string LongAddress { get; private set; }
		internal string LongAddressWithTab { get; private set; }
		internal string DynamicLabelStart { get; private set; }
		internal string DynamicLabelEnd { get; private set; }
		internal string RaiseErrorCheck { get; private set; }
		internal string MacroArgPrefix { get; private set; }
		internal Func<string, string, string, string> ProcessPCRelative { get; private set; }
		internal Func<string, string, string, string, string, string> ProcessArgCheck { get; private set; }
		internal string Name { get; private set; }
	}
}