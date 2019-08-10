#!/bin/bash
set -e
mkdir -p Drill.AppDir
cp -R Drill-GTK-linux-x86_64-release/* Drill.AppDir
mkdir -p Drill.AppDir/usr/share/metainfo
mkdir -p Drill.AppDir/usr/share/applications
cp Assets/GTK-Linux/drill.software.appdata.xml Drill.AppDir/usr/share/metainfo
cp Assets/GTK-Linux/drill-search-gtk.desktop Drill.AppDir/usr/share/applications
ln -s drill-search-gtk Drill.AppDir/AppRun
cp Assets/GTK-Linux/drill-search-gtk.svg Drill.AppDir
wget https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
export ARCH=x86_64 && ./appimagetool-x86_64.AppImage Drill.AppDir
test -f Drill-x86_64.AppImage
