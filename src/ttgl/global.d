module ttgl.global;

struct Version {
	int major, minor, revision;
}

enum string APPNAME = "TTGL";
enum Version VERSION = { major:1, minor:0 };
enum string PATH = "res";
enum string TITLE_FORMAT = "%s - FPS: %d (%.3fms)::S: %d";
static int FIELD = 512^^2;
