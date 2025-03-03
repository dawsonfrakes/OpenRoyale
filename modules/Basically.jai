Basic :: #import "Basic";

assert :: Basic.assert;

ascii_to_utf16lez :: (s: string) -> []u16 {
	utf16le: [..]u16;
	Basic.array_reserve(*utf16le, s.count + 1);
	for s Basic.array_add(*utf16le, it);
	Basic.array_add(*utf16le, 0);
	return utf16le;
}
