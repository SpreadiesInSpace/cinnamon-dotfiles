{
  lib,
  stdenv,
  fetchsvn,
  fetchFromGitHub,
  autoreconfHook,
  gnutls,
  libfilezilla,
  pkg-config,
  pugixml,
  wxGTK32,
}:

stdenv.mkDerivation rec {
  pname = "filezilla-server";
  version = "1.9.4";

  src = fetchFromGitHub {
    owner = "iynaix";
    repo = "filezilla-server";
    rev = "v${version}";
    hash = "sha256-f8kN7n9xekO44Rnqexr4XmGkV4Os+0+0NXx0Ssy/vbs=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    gnutls
    (libfilezilla.overrideAttrs {
      version = "0.49.0";
      src = fetchsvn {
        url = "https://svn.filezilla-project.org/svn/libfilezilla/trunk";
        rev = "11192";
        hash = "sha256-fm1cenGwYcPz0TtMzbPXrZA7nAzwo8toBNA9cW2Gnh0=";
      };
    })
    pugixml
    wxGTK32
  ];

  postInstall = ''
    mkdir -p $out/share/applications
    substitute $src/pkg/unix/filezilla-server-gui.desktop.in $out/share/applications/filezilla-server-gui.desktop \
        --replace-fail '@PACKAGE_VERSION@' ${version} \
        --replace-fail '/opt/filezilla-server/share/icons/hicolor/scalable/apps/filezilla-server-gui.svg' 'filezilla-server-gui' \
        --replace-fail '/opt/filezilla-server/bin/' ""

    mkdir -p $out/lib/systemd/system
    substitute $src/pkg/unix/filezilla-server.service.in $out/lib/systemd/system/filezilla-server.service \
        --replace-fail '/opt/filezilla-server/etc' '/etc/filezilla-server' \
        --replace-fail '@DEB_EXECSTART_WEBUI_ROOT@' "" \
        --replace-fail '/opt/filezilla' $out
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://filezilla-project.org/";
    description = "Free open source FTP and FTPS Server";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

# add the package to systemd.packages as well for the systemd service to be picked up
