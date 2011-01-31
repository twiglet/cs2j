package RusticiSoftware.System;

public interface IDisposable {
	void Dispose() throws Throwable;

	void close() throws Throwable;
}
