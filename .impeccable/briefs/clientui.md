# Surface brief: ClientUI (all client scenes)

Scope: connect, waiting, online game board, end game, lost connection, opponent disconnected, local test game. Mode: Experience on the board (the player is inside the game), Operate on the connect form.

## Direction contract

THESIS: A word is a metro line. The board is a transit network; tracing a word builds a line station by station under the 45° rule that Boggle adjacency already obeys. Refuses the category defaults: neon arcade tiles and cream wooden dice.

OWN-WORLD: Cool map-paper ground (#E7EAEE) with streets, parks, a river, and ghost lines carrying tiny trains. Stations are white roundels with thick ink rings (#17192B). Your line is vermillion (#D63A24), the opponent's is teal (#0F8577), and the departure board is ink with saffron (#F5B700) digits. Overpass Black for signage, Overpass Mono for the clock.

STORY: The player connects at a station-info panel, waits on a loop line, then builds lines. Each found word becomes a stop on their route strip. They watch the clock train run to its terminus and see whose line reached further.

FIRST VIEWPORT: Connect: "BOGGLE" drawn as six stations on a vermillion line that builds itself at left; an ink station-info panel with the form at right; "Se connecter" is a vermillion pill. Game: an ink departure board across the top (clock, the word being traced, scores) over a 4×4 station lattice centered on the map, with the route strip of found words at left.

FORM: Ligne de métro, ranked 1 of 7 (own ranking). seed: none (unavailable). The launcher was declined, so the roll did not run; the user chose from four presented directions.

Signature interaction: the trace. Stations adjacent to the line tip pulse a dashed "next stop" ring and the rest dim. Each segment grows into place with a rising chime. On release, a train runs the line and departs. When the score rises, the stations flash saffron and the word joins the route strip; when it doesn't, the stations shake.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
