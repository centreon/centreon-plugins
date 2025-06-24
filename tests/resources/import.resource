*** Settings ***
Documentation       This is the documentation for the import resource file.

Library             Examples
Library             DateTime
Library             OperatingSystem
Library             String
Library             XML
Library             Collections
Resource            resources.resource
Library             BuiltIn
Library             connector.py
Library             Process