// -*-go-*-
//
// Commonmark parser
// Copyright (c) 2017 Marius Orcsik <marius@habarnam.ro>
// MIT License
//

package cmarkparser

import(
    "log"
    "errors"
)

func Parse (data []byte) (Document, error) {
    return parse(data)
}

%% machine parser;
%% include character_definitions "characters.rl";
%% include blocks "blocks.rl";

%% write data;

func arr_splice(dst []byte, src []byte, pos int) []byte {
	var ret = make([]byte, 0)
	for _, a := range dst[:pos] {
		ret = append (ret, a)
	}
	for _, b := range src {
		ret = append (ret, b)
	}
	for _, c := range dst[pos+1:]{
		ret = append (ret, c)
	}
	return ret
}

func parse(data []byte) (Document, error) {
    //t_data = trimb(data)
    cs, p, pe := 0, 0, len(data)
    //ts, te, act := 0, 0, 0
    //log.Printf("%s", ts)
    eof := len(data)

    var doc Document = Document{}
    if pe == 0 {
        return doc, errors.New("Empty document")
    }

    var node Node
    var heading_level uint;
    var nodes Nodes;
    log.Printf("Incoming[%d]: \"%s\"\n", len(data), data)

    var mark int
    var thematic_break_symbol byte

    %%{
        action emit_eof {
            log.Printf("%s\n", nodes)
            doc.Children = nodes
            log.Printf("eof:%d:%d\n", p, eof)
        }

        action emit_add_block {
            if !node.Empty() {
                nodes = append(nodes, node)
                log.Printf("appending node: %s\n", node)
                node = Node{}
            }
            
        }
        single_line_doc = (any)+ >mark %emit_add_line;
        document = ((block %emit_add_block)* | (single_line_doc %emit_add_block));

        #main := |*
        #    block => emit_add_block;
        #    line => emit_add_line;
        #*|;

        main := document %eof emit_eof;
 
        write init;
        write exec;
    }%%

    return doc, nil
}
