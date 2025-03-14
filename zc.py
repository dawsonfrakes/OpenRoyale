root_file_path = "main_windows.z"
with open(root_file_path) as f: src = f.read()

def tokenize(s): return s.replace("(", " ( ").replace(")", " ) ").split()

class Symbol(str):
	def __repr__(self): return self
class Keyword(str):
	def __repr__(self): return "#" + self
class String(str):
	def __repr__(self): return "\"" + self + "\""
class Number(float): pass
class List(list):
	def __repr__(self): return "(" + " ".join(map(repr, self)) + ")"
Atom = Symbol | Keyword | String | Number
Exp = Atom | List

def parse(tokens):
	token = tokens.pop()
	if token == "(":
		L = List()
		while tokens[-1] != ")": L.append(parse(tokens))
		tokens.pop()
		return L
	elif token == ")": raise SyntaxError("unexpected )")
	elif token[0].isdigit(): return Number(token)
	elif token[0] == "#": return Keyword(token[1:])
	elif token[0] == "\"": return String(token[1:-1])
	else: return Symbol(token)

class Typespec: pass
class Struct(Typespec):
	def __init__(self):
		self.fields = {}

def doeval(x, env):
	if not isinstance(x, List):
		if isinstance(x, Symbol): return env[x]
		else: return x
	op, *args = x
	if op == Symbol("using"):
		rhs = doeval(args[0], env)
		assert isinstance(rhs, Struct)
		for key, value in rhs.fields.items(): env[key] = value
		return None
	elif op == Symbol("import"):
		rhs = doeval(args[0], env)
		assert isinstance(rhs, String)
		with open(rhs) as f: contents = f.read()
		print("Opening", rhs, contents)
		return Struct()
	elif op == Symbol(":"):
		name, typespec = args
		assert isinstance(name, Symbol)
		assert name not in env
		env[name] = None # doeval(typespec, env)
		return None
	else:
		proc = doeval(op, env)
		pargs = [doeval(arg, env) for arg in args]
		return proc(*pargs)
env = {}
tokens = list(reversed(tokenize(src)))
while len(tokens) > 0:
	exp = parse(tokens)
	print(exp)
	result = doeval(exp, env)
