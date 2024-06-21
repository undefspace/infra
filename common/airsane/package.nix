{
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  avahi,
  sane-backends,
  libpng,
  libusb1,
  libjpeg,
  lib,
  darwin,
  cmake,
}:
stdenv.mkDerivation rec {
  pname = "airsane";
  version = "0.4.1";
  src = fetchFromGitHub {
    owner = "SimulPiscator";
    repo = "AirSane";
    rev = "v${version}";
    hash = "sha256-s/HfhawbFwGVtFL+xqUw5IscwTMSCItSBvDe2v+TSPI=";
  };
  patches = [
    ./launchd.patch
    ./systemd.patch
    (fetchpatch {
      url = "https://github.com/SimulPiscator/AirSane/commit/449e950d72bce596a2e9cdb03dcf4852e1b1e8aa.patch";
      hash = "sha256-U6tk2JYcR2ASSL6Gi/gPABRGEuD4zX2BKlUhAI2rlpw=";
    })
  ];
  buildInputs = [
    avahi
    sane-backends
    libpng
    libusb1
    libjpeg
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Foundation ]);
  nativeBuildInputs = [ cmake ];
}
