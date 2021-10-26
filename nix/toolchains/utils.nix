{ lib }:

{
  targetTripleEnv = s: lib.toUpper (lib.replaceChars [ "-" ] [ "_" ] s);
}
