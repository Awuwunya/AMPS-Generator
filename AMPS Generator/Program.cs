using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace AMPS_Generator {
	class Program {
		static readonly Func<string, Configuration> GetConfig = (s) => {
			switch (s.ToUpperInvariant()) {
				case "TEST": return Configuration.Test;
				case "SONIC1": return Configuration.Sonic1;
				case "SONIC2": return Configuration.Sonic2;
			}

			Console.Write("Invalid assembler " + s + "!");
			Console.ReadKey();
			Environment.Exit(-1);
			return default(Configuration);
		};

		static readonly string[] CheckValidFolder = {
			"AMPS", @"AMPS\code", @"AMPS\code\68k Initialize.asm"
		};

		public static Configuration Config;
		public static AssemblerInfo Assembler;
		static readonly Regex ValidKey = new Regex("^[A-Z0-9]{2,}$", RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);

		static void Main(string[] args) {
			if(args.Length < 2) {
				Console.Write(
					"Usage: \"AMPS Generator\" <assembler> <output>\n" +
					"<config> : Configuration to target. The configuration determines all params.\n" +
					"<output> : Folder to output data to, replacing or creating any files here.\n" +
					"This tool was created to help standardize and make working with the multi-source" +
					"setup easier for me. This source is released on Github to make it easier to\n" +
					"contribute any changes to AMPS for anyone else."
				);

				Console.ReadKey();
				return;
			}

			// update assembler
			Config = GetConfig(args[0]);
			Assembler = Config.Assembler;

			// check if folder ends with a slash
			string folder = args[1];
			if(!folder.EndsWith("\\") && !folder.EndsWith("/")) {
				folder += "\\";
			}

			// figure out if the current and output folders are actually correct
			foreach (string find in CheckValidFolder) {
				if (!File.Exists(find) && !Directory.Exists(find))
					Error($"Input directory \"{Directory.GetCurrentDirectory()}\" is not valid!");
				if (!File.Exists(folder + find) && !Directory.Exists(folder + find))
					Error($"Output directory \"{folder}\" is not valid!");
			}

			// process each file
			foreach(string src in Directory.GetFiles("AMPS", "*", SearchOption.AllDirectories)) {
				// ignore specific files
				if (src == "AMPS\\Includer.exe.config" || src == "AMPS\\Includer.pdb")
					continue;

				byte[] dat = File.ReadAllBytes(src);
				string dst = folder + src;

				if (dat.Length >= 4 && dat[0] == ';' && dat[1] == 'G' && dat[2] == 'E' && dat[3] == 'N' && dat[4] == '-') {
					// determine type
					string enc = "" + (char)dat[5] + (char)dat[6] + (char)dat[7];
					int offset = 8;

					while (dat.Length >= offset && (dat[offset] == '\n' || dat[offset] == '\r' || dat[offset] == '\t' || dat[offset] == ' '))
						offset++;

					// reset variables
					Assembler.ResultPCRelative = "<unset>";
					IfPosition = new List<Tuple<bool, int>>();

					switch (enc.ToLowerInvariant()) {
						case "asm": {
								Console.WriteLine($"ASM ENCODED {src}");
								Text = Encoding.UTF8.GetString(dat, offset, dat.Length - offset);
								ProcessASM(dst);
								break;
							}

						default:
							Error($"Invalid file encoding {enc} encountered. Valid encodings are: ASM and S2A!");
							break;
					}

				} else {
					// this is a normal file, just copy
					Console.WriteLine($"COPY {src}");
					File.Copy(src, dst, true);
				}
			}

			Console.WriteLine($"Finished!");
			Console.ReadKey();
		}

		static int Idx;
		static string Text;
		static List<Tuple<bool, int>> IfPosition;

		private static void ProcessASM(string dst) {
			int last = 0, idx2 = 0;

			// find each replace region
			while((Idx = Text.IndexOf("%", last)) >= 0) {
				if((idx2 = Text.IndexOf("%", Idx + 1)) < 0) {
					break;
				}

				// check if this is an invalid sequence
				if(idx2 - Idx <= 2) {
					last = Idx + 1;
					continue;
				}

				// get the data we want
				string data = Text.Substring(Idx + 1, idx2 - Idx - 1).ToLowerInvariant();

				// check if it is actually valid
				if (!ValidKey.IsMatch(data)) {
					last = Idx + 1;
					continue;
				}

				if (KeyReplace.ContainsKey(data)) {
					// replace dictionary entry
					string res = KeyReplace[data]();
					Text = Text.Substring(0, Idx) + res + Text.Substring(idx2 + 1);
					Idx -= res.Length + 2;

				} else if (KeyProc.ContainsKey(data)) {
					// processed dictionary entry
					int end;
					if ((end = Text.IndexOf("\n", idx2)) < 0)
						end = Text.Length;

					// process the entry
					string param = Text.Substring(idx2 + 1, end - idx2 - 1);
					if (param.StartsWith(" ")) param = param.Substring(1);
					if (param.EndsWith("\r")) param = param.Substring(0, param.Length - 1);

					// load result and reload the next position
					string res = KeyProc[data](Idx, param);
					if ((end = Text.IndexOf("\n", Idx)) < 0)
						end = Text.Length;
					
					Text = Text.Substring(0, Idx) + res + Text.Substring(end + 1);
					Idx -= res.Length + 2;
				}

				// go to next case
				last = Idx + 1;
			}

			if(IfPosition.Count != 0) {
				Error($"Unexpected if without an endif.");
			}

			// write the changes back
			File.WriteAllText(dst, Text);
		}

		private static readonly Dictionary<string, Func<string>> KeyReplace = new Dictionary<string, Func<string>>(){
			{ "kt",  () => { return Assembler.ASM68KTab; } },
			{ "at",  () => { return Assembler.ASTab; } },
			{ "re",  () => { return Assembler.RSEq; } },
			{ "rb",  () => { return Assembler.RSB; } },
			{ "rw",  () => { return Assembler.RSW; } },
			{ "rl",  () => { return Assembler.RSL; } },
			{ "rsset",  () => { return Assembler.RSSet; } },
			{ "reven",  () => { return Assembler.RSEven; } },
			{ "ralign",  () => { return Assembler.RSAlign; } },
			{ "mq",  () => { return Assembler.MoveqFix2; } },
			{ "equ",  () => { return Assembler.Equ; } },
			{ "set",  () => { return Assembler.Set; } },
			{ "mvq",  () => { return Assembler.MoveqFix; } },
			{ "xor",  () => { return Assembler.Xor; } },
			{ "mod",  () => { return Assembler.Mod; } },
			{ "endr",  () => { return Assembler.Endr; } },
			{ "laddr",  () => { return Assembler.LongAddress; } },
			{ "laddrt",  () => { return Assembler.LongAddressWithTab; } },
			{ "dlbs",  () => { return Assembler.DynamicLabelStart; } },
			{ "dlbe",  () => { return Assembler.DynamicLabelEnd; } },
			{ "tlbl",  () => { return Assembler.TempLabel; } },
			{ "pcrelref",  () => { return Assembler.ResultPCRelative; } },
			{ "macpfx",  () => { return Assembler.MacroArgPrefix; } },
			{ "warning",  () => { return Assembler.Warning; } },
			{ "fatal",  () => { return Assembler.Fatal; } },
			{ "raiseerror",  () => { return Assembler.RaiseErrorCheck; } },
			{ "features",  () => { return Config.Flags.Build(); } },
		};

		private static readonly Dictionary<string, Func<int, string, string>> KeyProc = new Dictionary<string, Func<int, string, string>>(){
			{ "pcreldef", (offs, data) => {
				try {
					Match m = new Regex(@"^(\.?[A-Za-z0-9_]+)[\s\t]*([\(\)\.A-Za-z0-9_\-\$\+\*/%]+)(.*)$").Match(data);
					return Assembler.ProcessPCRelative(m.Groups[1].Value, m.Groups[2].Value, m.Groups[3].Value);

				} catch (Exception ex) {
					Error($"Unable to convert arguments to correct format. Expected format: templabel expression comment\n\nError: {ex.ToString()}");
				}

				return "%null%";
			} },
			{ "ifasm", (offs, data) => {
				IfPosition.Insert(0, new Tuple<bool, int>(Assembler.Name.Equals(data.Trim(), StringComparison.InvariantCultureIgnoreCase), offs));
				return "";
			} },
			{ "narg", (offs, data) => {
				try {
					Match m = new Regex(@"^[\s\t]*([^\s\t]*) *([A-Za-z0-9]+) *(\=\=|\<\>) *(else)?(.*)$").Match(data);
					return Assembler.ProcessArgCheck(m.Groups[1].Value, m.Groups[2].Value, m.Groups[3].Value, m.Groups[4].Value, m.Groups[5].Value);

				} catch (Exception ex) {
					Error($"Unable to convert arguments to correct format. Expected format: comparison argname\n\nError: {ex.ToString()}");
				}

				return "%null%";
			} },
			{ "endif", (offs, data) => {
				if(IfPosition == null || IfPosition.Count <= 0)
					Error($"Unexpected endif without an if.");

				if(!IfPosition[0].Item1){
					Text = Text.Substring(0, IfPosition[0].Item2) + Text.Substring(offs);
					Idx -= offs - IfPosition[0].Item2;
				}

				IfPosition.RemoveAt(0);
				return "";
			} },
		};

		public static void Error(string msg) {
			Console.ForegroundColor = ConsoleColor.Red;
			Console.WriteLine(msg);
			Console.ReadKey();
			Environment.Exit(-1);
		}
	}
}
