#!/usr/bin/python3

import sys
import os.path
from lxml import etree as ET

def expand_src_path(path):
    head, _, tail = path.partition(os.path.sep)
    _, level, _ = head.split('-')
    return os.path.join('../' * (int(level) + 1), tail)

def expand_rel_path(project_dir, path):
    return os.path.normpath(os.path.join(project_dir, "dummy", path))

def option(xml, super_class):
    return xml.find('//option[@superClass="%s"]' % super_class).attrib['value']

def options(xml, super_class):
    for o in xml.xpath('//option[@superClass="%s"]/listOptionValue' % super_class):
        yield o.attrib['value']

def main(args):
    project_dir = args[1]
    project = ET.parse(os.path.join(project_dir, ".project"))
    cproject = ET.parse(os.path.join(project_dir, ".cproject"))

    print("# generated by %s" % args[0])
    for x in project.xpath('//projectDescription/linkedResources/link/*[self::location or self::locationURI]'):
        if not x.text.endswith('.txt'):
            print("SRCS += %s" % expand_rel_path(project_dir, expand_src_path(x.text)))
    for o in options(cproject, 'gnu.c.compiler.option.preprocessor.def.symbols'):
        print("CDEFINES += %s" % o)
    for o in options(cproject, 'gnu.c.compiler.option.include.paths'):
        print("INCDIR += %s" % expand_rel_path(project_dir, o))
    for o in options(cproject, 'gnu.cpp.link.option.paths'):
        print("LIBDIR += %s" % expand_rel_path(project_dir, o))
    for o in options(cproject, 'gnu.cpp.link.option.libs'):
        print("LIBS += -l%s" % o)
    ldscript = option(cproject, 'fr.ac6.managedbuild.tool.gnu.cross.c.linker.script')
    print("LDSCRIPT := %s" % expand_rel_path(project_dir, ldscript))

if __name__ == "__main__":
    main(sys.argv)