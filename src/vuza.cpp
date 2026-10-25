// vuza.cpp -- a small Scheme for sound
//

#include "vuza.h"

using namespace std;

// usage: vuza [file ...] [-] [-- arg ...]   files are loaded in order (a prelude, then a script); "-" starts the REPL;
// the strings after "--" are the list args, for the script
int main(int argc, char** argv) {
    EnvPtr env = core();
    int n = argc;                                              // the arguments before "--"
    List args;
    for (int i = 1; i < argc; ++i) if (string(argv[i]) == "--") {
        n = i;
        for (int j = i + 1; j < argc; ++j) args.push_back(cell(string(argv[j])));
        break;
    }
    env->vars["args"] = cell(args);
    for (int i = 1; i < n; ++i) {
        if (string(argv[i]) == "-") {
            repl(env);
            continue;
        }
        try {
            load({cell(string(argv[i]))}, env);
        } catch (Error& e) {
            report(e, cerr);
            return 1;
        }
    }
    if (n == 1) {
        cout << "[vuza, v0.3]" << endl;
        cout << "a small Scheme for sound" << endl << endl;

        repl(env);
    }
    return 0;
}

// eof
