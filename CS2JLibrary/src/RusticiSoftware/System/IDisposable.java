package RusticiSoftware.System;

public interface IDisposable {
	void Dispose() throws Exception;

	void close() throws Exception;
}
