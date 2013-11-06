#!/usr/bin/env python

from lxml import etree


def parse_gsmarkup(gs_file, root_element):
    gs_file = open(gs_file)
    with gs_file as xml_doc:
        context = etree.iterparse(xml_doc, events=("start", "end"))
        base = False
        child_list = []

        for event, elem in context:
            if event == "start" and elem.tag == root_element:
                # Mark the start of our subtree, at tag parent_element
                base = elem.tag
            elif event == "end" and elem.tag == root_element:
                # Mark the end of our subtree search
                #print base + ":" + str(child_list)
                base= False
                elem.clear()
                return child_list
            elif event == "start" and base:
                child_list.append(elem.tag)
            elif event == "end" and base:
                # Search our subtree for the child elements
                children = elem.getchildren()
                for child in children:
                    if child.tag is not etree.Comment:
                        child_list.append(child.tag)

# Get unique identifiers tying instantiated cocoa objects to Python objects
# Have vernacular send all selector signatures to Python
# Use metaclasses to access these objects as remote objects
# How to create new GUI objects in Python and instantiate them remotely
print parse_gsmarkup("calculator.gsmarkup", "objects")
print parse_gsmarkup("calculator.gsmarkup","connectors")
