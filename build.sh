#!/bin/bash

echo "Rebuilding dependencies"
flutter packages pub run build_runner build --delete-conflicting-outputs 
echo "Clear project.."
flutter clean
echo "Getting dependencies..."