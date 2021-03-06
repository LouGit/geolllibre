#!/usr/bin/rebol -qs
REBOL [
	Title:   "GeolPDA report generator"
	Date:    16-Dec-2016/21:45:50+3:00
	Version: 1.0.0
	File:    %gll_geolpda_report_generator.r
	Purpose: {
		Génération d'un rapport sous forme d'un fichier .html
		à partir d'une base sqlite "geolpda" du geolpda
		en allant chercher la table des observations avec les données:
		_id,poiname,poitime,elevation,poilat,poilon,photourl,audiourl,note
		"94","PCh2012_0372","1351959798292","544.3","43.4495","0.733307","1351959861748.jpg","1351959897130.3gpp","Le Bouche à oreille, café, logiciels libres, tango studio"
		"93","PCh2012_0371","1351700656858","91.1","5.37645","-3.96311","","","chez PNG"
		Le fichier sqlite doit se situer là (répertoire courant):
			geolpda
		Et les photos doivent être là (en aval du répertoire courant):
			photos/
	}
	History: [
		0.1.0 15-Nov-2012               "PCh: J'écris vite fait un script qui fabrique un .html de mes données collectées avec le geolpda"
		0.2.0 17-Nov-2012               "PCh: Youpi, mon programme Rebol a généré un rapport à peu près potable:"
		0.2.1 10-Dec-2012               "PCh: Je fais un exemple de rapport de geolpda: quelques modifications"
		0.2.2 8-Mar-2013                "PCh: Tri des observations en fonction du timestamp, et non de l'id (problème de tri asciibétique)"
		0.2.2 09-Mar-2013               "A version marked"
		0.2.3 2-Apr-2013/11:59:57+2:00  "Ajout license et copyright"
		0.2.4 15-Apr-2013/14:08:11      "Prise en compte du cas ou le .csv a une ligne vide à la fin"
		0.2.5 11-Sep-2013/20:01:21+2:00 "Débogage, corrections; prise en compte de dates de début et fin pour générer le rapport"
		0.2.6 25-Oct-2013/16:46:25      "Continue coding gll_geolpda_fetch_data.r; moved functions from gll_geolpda_report_generator to gll_routines, so that they ca be available to all gll_geolpda* programs. ATTENTION! TODO left epoch-to-date function in gll_geolpda_report_generator, so that this program can still run as standalone; but this function should be ERASED."
		0.8.0 8-Nov-2013/13:24:46+1:00  "Take data from sqlite base, instead of .csv files"
		0.8.1 14-Nov-2013/12:34:23      "Begin of changes so that gll_geolpda_report_generator.r directly connects to geolpda sqlite database, instead of taking information from .csv generated by geolpda program => not finished."
		0.8.2 25-Dec-2013/22:51:22      "Changes done nearshore Cameroon, Bakassi area, for generation of report from GeolPDA. Détection de séquences de dates, pour choisir parmi des séquences => ne fonctionne pas, à reprendre"
		0.8.3 24-Jan-2014/14:03:28      "Modif of GéolPDA to GeolPDA: tant pis for AllGood, tant mieux for i18n..."
		0.8.4 12-Feb-2014/12:09:12      "Modifs in Amazonia: get data from sqlite database from GeolPDA."
		0.8.5 7-Mar-2014/18:00:50       "Round latitude and longitude to a decent amount of decimal places for HTML output."
		0.9.0 9-Mar-2014/22:24:10+1:00  "Include structural measurements in HTML report."
		0.9.1 23-Apr-2014/19:19:46+1:00 "Moved functions to gll_routines.r"
		0.9.2 6-Jun-2014/13:01:33+2:00  "Improve date handling from command line arguments: default end date is now; anglicise a few variables names; a bit of code cleaning"
		0.9.3 23-Mar-2015/14:45+1:00	"Add information about samples in report"
		1.0.0 16-Dec-2016/21:45:50+3:00 "Version 1 should have been granted way before, since gll_geolpda_report_generator.r is used routinely in production"
	]
License: {
This file is part of GeolLLibre software suite: FLOSS dedicated to Earth Sciences.
###########################################################################
##          ____  ___/_ ____  __   __   __   _()____   ____  _____       ##
##         / ___\/ ___// _  |/ /  / /  / /  /  _/ _ \ / __ \/ ___/       ##
##        / /___/ /_  / / | / /  / /  / /   / // /_/_/ /_/ / /_          ##
##       / /_/ / /___|  \/ / /__/ /__/ /___/ // /_/ / _, _/ /___         ##
##       \____/_____/ \___/_____/___/_____/__/_____/_/ |_/_____/         ##
##                                                                       ##
###########################################################################
  Copyright (C) 2013 Pierre Chevalier <pierrechevaliergeol@free.fr>
 
    GeolLLibre is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
    or write to the Free Software Foundation, Inc., 51 Franklin Street, 
    Fifth Floor, Boston, MA 02110-1301, USA.
    See LICENSE file.
}]

;******************************************************************************
; TODO:
;     o generate a couple of data files, .csv, or optionnaly a database dump, of the reported data.
;     o à la fin, choisir d'uploader sur un ftp, et d'émailler l'alerte à quidedroit
;     o inclure la réduction des photos dans le script
;     o faire en sorte qu'un clic, dans le .html, sur les images, ouvre l'image 
;       en grand format dans le navigateur
;	
; 		=> 23-Oct-2013/9:55:53+2:00: see gll_geolpda_fetch_data.r
;		=> 6-Feb-2014/23:58:48-3:00: essayons
;	
;     o le outputfile est curieusement créé dans le répertoire du script, 
;       soit ~/bin, sur ma machine autan:
;       il faudrait qu'il le crée dans le répertoire d'où on lance le script.
;       comme pis-aller, je fais un symlink à chaque fois...
;
;    o mettre des symbole structuraux, sous forme de Tés ou stéréos ou rosaces
;
;    o générer des cartelettes par jour ou parcours ou regroupement géographique
;       de points d'observations
;
;    o faire une interface graphique
;      => cf. gll_geolpda_data_mgr.r
;
;    o faire une interface utilisateur VID avec choix des dates à reporter, 
;      élimination manuelle de certains points à ne pas mettre dans le rapport 
;      (genre "bon resto", "pêche mémorable", etc.)
;
;    o prévoir un champ "reporting" booléen dans la table des observations,
;      valide par défaut, qu'on puisse décocher au moment de la prise de note,
;      de manière à ne point reporter tous les endroits où l'on défèque ou les 
;      meilleures gargottes ou autres lieux de perdition dans le rapport 
;      d'intervention destiné au client.
;
;    o choisir d'attaquer soit la base sqlite geolpda, soit la base bdexplo, 
;      qui a été nourrie au préalable.
;
;    o faire tourner directement sur le téléphone => migrer en Red
;
;    o générer quelque chose de mieux que du html => LaTeX, cf. Jerry
;
;    o ouvrir le fichier avec un chemin à choisir
;
;******************************************************************************
; DONE:
;
;     x à terme, attaquer direct la base sqlite geolpda => auquai
;
;******************************************************************************

;date_start: now - 10
;date_end:   now
flag_create_tec_files: true		; default

; Get routines, preferences, and connect to database, if not already done:
if [none? dir_geolpda_local] [
	do load to-file system/options/home/bin/gll_routines.r ]
; dates and flags may be defined elsewhere, if this script is called from another script:
if error? try [any [(none? date_start) (none? date_end)]] [
	date_start: date_end:  none ]
if error? try [(none? flag_create_tec_files)] [
	flag_create_tec_files: none ]

; Process command line arguments:
unless (none? system/options/args) [
	arguments: copy system/options/args
	; on traite les options en -quelquechose et on les ôte, pour ne garder que les dates:
	; process options -something and discard them, in order to only keep dates arguments:
	arguments: head arguments
	while [not (tail? arguments)] [
		a: to-string first arguments
		if ((left a 1) = "-") [
				if a = "-t" [flag_create_tec_files:  true]
				if a = "-d" [flag_create_data_files: true] ; TODO implémenter cela
				remove arguments a ]
		arguments: next arguments  ]
	arguments: head arguments
	; Get dates for report to be generated, from command line arguments, now discarded from all -options:
	if error? try [
		switch length? arguments [
			2 		[	date_start: to-date pick arguments 1
						date_end:   to-date pick arguments 2	]
			1 		[	date_start: to-date pick arguments 1
						date_end:   now/date					]
			0 		[	print "No dates supplied on command-line; continue execution"			]
			(> 2) 	[ 	print "Too many arguments supplied on command-line; continue execution"	] ]
	] [
		print "Error: one flag (-t to generate TecTri files) and/or one or two arguments may be used: starting date and optionnaly ending date (defaults to now), both in Rebol-Red compatible format, i.e. 23-Apr-2014 or 23/04/2014; ignore arguments and continue execution"
] ]

; *** on fait tourner la fonction qu'on souhaite, au choix: get_geolpda_data_from_csv, get_geolpda_data_from_sqlite ou get_geolpda_data_from_postgresql:
get_geolpda_data_from_postgresql  ;TODO restrain this query to the range of dates defined by date_start and date_end; this will considerably speed things up.

	; Il s'agit maintenant de déterminer les jours où il y a eu des observations: [{{{
	run_query "SELECT DISTINCT date FROM public.field_observations ORDER BY date"	; nettement plus aisé en sql qu'à partir des données du .csv!
	jours: copy []
	foreach i sql_result [
		unless any [(none? i) ((to-string i) = "none")] [
			append jours to-date to-string i
	] ]
	;length? jours
	;}}}]
	if (none? date_start) [
		print "Jours avec des observations enregistrées dans la base: "
		;foreach j jours [print j]   ; <= la liste des jours, triée
		foreach j contig_sequences jours [print j] ]

; On affiche combien on a de lignes (d'observations)								<= non, déjà fait plus haut
;print rejoin ["Nombre d'observations: "          length? geolpda_observations]
;print rejoin ["Nombre de mesures structurales: " length? geolpda_orientations]

; 2013_09_11__15_51_45: j'essaye de faire une liste des séquences contigües de dates,
; pour donner le choix des séquences à traiter à l'utilisateur.
; => 2016_11_30__23_39_12 implémenté dans gll_routines.r, fonction contig_sequences
;contig_sequences TODO mettre en application, maintenant

if (none? date_start) [	; if date_start is not defined, date_end is also undefined
	; {{{ ask start and end dates: } } }
	; =============================================================================
	; TODO: paramétrer les dates de début et fin de la génération du rapport
	; =============================================================================
	prin rejoin ["Date de début de génération du rapport (défaut: " (to-string first jours) ": "]
	date_start: input
	either date_start = "" [date_start: first jours] [date_start: to-date date_start]
	?? date_start
	prin rejoin ["Date de fin de génération du rapport (défaut: " (to-string last jours) ": "]
	date_end: input
	either date_end = "" [date_end: last jours] [date_end: to-date date_end]
	?? date_end
] ; }}}

;html_report_generator: function [ "Generate an HTML report file" date_start [date!] date_end [date!]] [ ;{{{
; Shall we create .tec files for use with TecTri?
if (none? flag_create_tec_files) [
	ans: lowercase ask "Shall we create .tec files for use with TecTri? [Y/n]"
	either any [(ans = "") (ans = "y")] [ flag_create_tec_files: 1 ]
    	                                [ flag_create_tec_files: 0 ]
]
; Création d'un fichier .html en sortie {{{ } } }
;==============================================================================
; Créons un fichier .html en sortie, en y ouvrant un port:/*{{{*/ } } }
; Le fichier est nommé en fonction du dernier jour;
; next form 100 est un truc pour avoir des leading zeroes.
outputfile: to-file rejoin ["geolpda_report_pch_from_"
date_start/year "_"
next form 100 + date_start/month "_"
next form 100 + date_start/day
"_to_"
date_end/year "_"
next form 100 + date_end/month "_"
next form 100 + date_end/day ".html"]
;/*}}}*/
; On y écrit un en-tête général: [{{{
write/lines outputfile to-string [
{<!DOCTYPE HTML PUBLIC ^"-//W3C//DTD HTML 4.01 Transitional//EN^">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <style type="text/css">
   div {
    overflow:auto; max-height:200px;
    border: 1px solid; margin: 1px; padding: 10px; width:90%;}
   img {
    border: 1px solid;
    max-width:  400px;
    max-height: 400px;
   }
   body { counter-reset: chapter; }
   h1:before { 
          content: counter(chapter) ". ";
       counter-increment: chapter;
   }
   h1 {    counter-reset: section; }
   h2:before { 
       content: counter(chapter) "." counter(section) ". ";
       counter-increment: section;
   }
   h2 {    counter-reset: sssection; }
   h3:before { 
       content: counter(chapter) "." counter(section) "." counter(sssection) ". ";
       counter-increment: sssection;
   }
  </style>
  <title>
  }]
; TODO WARNING! 22 lines above:  solid; or solid (no ;)

write/lines/append outputfile rejoin ["Rapport d'observations de terrain collectées par GeolPDA du " (to-string date_start) " au " (to-string date_end)]
write/lines/append outputfile [{
  </title>
 </head>
<body>
<p align="right"><small>
<pre>
###########################################################################
##          ____  ___/_ ____  __   __   __   _()____   ____  _____       ##
##         / ___\/ ___// _  |/ /  / /  / /  /  _/ _ \ / __ \/ ___/       ##
##        / /___/ /_  / / | / /  / /  / /   / // /_/_/ /_/ / /_          ##
##       / /_/ / /___|  \/ / /__/ /__/ /___/ // /_/ / _, _/ /___         ##
##       \____/_____/ \___/_____/___/_____/__/_____/_/ |_/_____/         ##
##                                                                       ##
###########################################################################
</pre>
</small></p>
</center></em></div>
<p>
}]

write/lines/append outputfile to-string now/date
write/lines/append outputfile rejoin ["<p><small>Report generated on "
 to-string now " by gll_geolpda_report_generator.r</small></p>"]
;}}}]
;  puis on écrit le corps:/*{{{*/
; Itérons maintenant sur les jours; j est le jour courant:
;?? date_start
;?? date_end
foreach j jours [
	;prin j
	; on restreint aux dates définies plus haut:
	if ((j >= date_start) and (j <= date_end)) [
		; Écrivons un en-tête pour ce jour: journée = titre de niveau 1:
		print "=============="
		print j
		print "=============="
		;PRINT "DEBUG_1" ?? j input ;###############################################################DEBUG
		write/append outputfile rejoin ["<p></p>" {<hr size="2" width="100%"><br>} "<h1>" to-string j "</h1>"]
		; On ne considère que les observations faites le jour dit:
		foreach o geolpda_observations [
			;if o/1 = "PCh2012_0383" [ halt  ;###############################################################DEBUG
			;	;il y a là une date aberrante:
			;		;PCh2012_0383 1354924679009 0 0 0   
			;		;** Script Error: Invalid argument: 7-Dec-2012/23:57:592:00
			;		;** Where: to-date
			;		;** Near: to date! :value
			;	print "date aberrante: " o/2
			;	]
			;PRINT "DEBUG_2" ?? o input       ;###############################################################DEBUG
			if error? err: try [		; in case a date is none, for records which were not generated from a GeolPDA device
				tmp: epoch-to-date to-integer ((to-decimal o/3) / 1000)
				timestamp: to-date tmp 
				] [ timestamp: to-date "01-Jan-0000"]	; arbitrary very old date, when GeolPDA did not exist, AFAIK.
			;PRINT "DEBUG_3" ?? timestamp print timestamp/date ?? j input ;###############################################################DEBUG
			if (timestamp/date = j) [ ; on est dans le jour courant, on procède:
				;PRINT "DEBUG_4" input ;###############################################################DEBUG
				;print timestamp/date
				;print timestamp/date = j
				;input ;###############################################################DEBUG
				; des variables aux noms explicites:
				;poiname,poitime,elevation,poilat,poilon,photourl,audiourl,note
				id:          to-string  o/2
				alt:         to-decimal o/4
				lat:         to-decimal o/5
				lon:         to-decimal o/6
				photos:      to-string  o/7
				audio:       to-string  o/8
				note:        to-string  o/9
				sample_id:   to-string  o/10
				prin rejoin [id ": "]
				; discret à droite, l'heure:
				write/lines/append outputfile rejoin [ {<p align="right"><small>} timestamp/time "</small></p>" ]
				; Un titre de niveau 2 = le waypoint:
				write/lines/append outputfile rejoin [
				"<h2>" id ": "
				either lat >= 0 ["N"] ["S"]
				absolute (round/to lat 1E-6) "° " 
				either lon >= 0 ["E"] ["W"]
				absolute (round/to lon 1E-6) "°, z = "
				absolute (round/to alt 1E-2) "m"
				"</h2>"]
				; les notes:
				prin rejoin ["notes (" (length? note) " characters)"]
				write/lines/append outputfile rejoin ["<p>" note "</p>"]
				; les échantillons:
				unless any [(sample_id = "none") (none? sample_id) (sample_id == "")] [
					samples: parse/all (replace sample_id " " "") ";"
					prin rejoin [", " length? samples " sample" ]
					if ((length? samples) > 1) [prin "s"]
					write/append outputfile {
					<table border="1">
					  <tr>
						<th align="center">Sample ID</th>
						<th align="center">Assay results</th>
					  </tr>
					}
					foreach s samples [
						write/lines/append outputfile rejoin [ {
						  <tr valign="top">
							<td align="center">} s {</td>
							<td align="right"></td>
						  </tr>}
							; TODO: put assay results, if/when available
						]
					]
					write/lines/append outputfile {</table>}
				]
				; les mesures structurales:
				; first, are there any structural measurements concerning the current observation:
				run_query rejoin ["SELECT count(*) FROM public.field_observations_struct_measures WHERE obs_id = '" id "'"]
				nb_orientations: to-integer sql_result/1/1
					if ( nb_orientations > 0 ) [
						prin rejoin [", " nb_orientations " measures"]
						either (nb_orientations = 1) [	write/lines/append outputfile "<dl><dt>Structural measurement:</dt><dd>"   ] [ 
														write/lines/append outputfile "<dl><dt>Structural measurements:</dt><dd>" ]
						write/lines/append outputfile "<tt>"
						; If a stereonet has already been produced by a third-party app and is named
						; with the id.jpg, in the current directory, then include it in the html output.
						stereo_image_filename: to-file lowercase rejoin [id ".jpg"]
						if exists? stereo_image_filename [
;							print "YOUPI! UN STÉRÉO!"
							write/append outputfile rejoin [
								{<img src="} stereo_image_filename
								{" align="right" vspace="5" hspace="10" style="border: none" alt="}
								stereo_image_filename
								{"/>}
								{<br>}
							]
						]
								;{" align="right" vspace="5" hspace="10" alt="} ; this was left by a merge conflict, just a little bit above; left here justincase.
						; **attention! following line queries the postgresql database; code to be adapted to sqlite, if needed:
;						run_query rejoin ["SELECT obs_id, structure_type, north_ref, geolpda_id, geolpda_poi_id, measure_type, rotation_matrix FROM public.field_observations_struct_measures WHERE obs_id = '" id "' ORDER BY geolpda_poi_id, geolpda_id"]
						run_query rejoin ["SELECT obs_id, structure_type, north_ref, geolpda_id, geolpda_poi_id, measure_type, rotation_matrix, direction, dip, dip_quadrant, pitch, pitch_quadrant, movement, valid, comments FROM public.field_observations_struct_measures WHERE obs_id = '" id "' ORDER BY geolpda_poi_id, geolpda_id"]
						measures: sql_result
						foreach m measures [
							; o name is already an Observation: s stands for Structure:
							;prin "-"
							; Get measurement data from fields, rather than recompute from rotation_matrix, and make an orientation object based on fields data:
							either not (none? m/8) [
								s: orientation
								s/plane_direction:     m/8
								s/plane_dip:           m/9
								s/plane_quadrant_dip:  m/10
								s/line_pitch:          m/11
								s/line_pitch_quadrant: m/12
								s/line_movement:       m/13
							] [ ; no plane_direction; is there a rotation matrix?
								either not (none? m/7) [
									; there is a rotation matrix: compute an orientation from the matrix
									s: orientation/new first (to-block m/7)	; Bugs if there is no rotation matrix.
								] [
									; No matrix, no direction... Do nothing... TODO clarify this, at some point.
								]
							]
							; Oops: line azimut and dip are not listed in public.field_observations_struct_measures table;
							; therefore, if a line measurement is to be listed, we must work the orientation from the matrix:
							if (m/6 = "L") [s: orientation/new first (to-block m/7)]
							; which type of geometry is measured:
							parse m/6 [
								  "PLMS" (ttt: rejoin ["plane + line, movement sure " s/print_plane_line_movement])
								| "PLM"  (ttt: rejoin ["plane + line, movement "      s/print_plane_line_movement])
								| "PL"   (ttt: rejoin ["plane + line "                s/print_plane_line         ])
								| "P"    (ttt: rejoin ["plane "                       s/print_plane              ])
								| "L"    (ttt: rejoin ["line "                        s/print_line               ])
							]
							write/lines/append outputfile  rejoin [ttt "<br>"]
						]
						write/lines/append outputfile "</tt></dd></dl>"
						if (flag_create_tec_files = 1) [ ; creation of a TecTri file for the current observation point
							generate_tectri_file/criteria/unique_filename (rejoin ["WHERE obs_id = '" id "'"]) (rejoin [id ".tec"])
						]
					]
				if ((length? photos) > 0) [
					; Il y a des photos:
					;write/append outputfile photos
					;photos: "1342804479678.jpg;1342804628278.jpg;1342804641423.jpg"
					;print photos
					photos_list: to-list parse/all photos ";"
					prin rejoin [", photos: " length? photos_list]
					foreach pho photos_list [
						;prin rejoin [pho " "]
						;prin "-"
						; removed: useless, and it crashes if a jpg filename is not a number (case when pictures taken from different device, for instance):
						;tt: to-integer ((to-decimal first parse pho ".") / 1000)
						;timestamp_photo: to-date epoch-to-date tt
						;print timestamp_photo
						write/append outputfile rejoin [
							; TODO faire en sorte que les photos en portrait ne s'affichent pas plus petites que celles en paysage
							{<img src="} clean-path dir_geolpda_local {photos/} 
							pho 
							{" vspace="5" hspace="10" alt="} 
							pho 
							{"/>} 
						]
						; there was: {" style="width="25%" height="25%";" vspace="5" hspace="10" alt="} => no good
						; {<img src="file://} system/options/path "photos/" pho {" style="width="25%" height="25%";" vspace="5" hspace="10" alt="} pho {" />}
						; plutôt, voir thumbnail-maker.r
						;  {<img alt="} pho {" src="file:///home/pierre/geolpda/copie_android_media_disk/photos/reduit_700/} pho {" " />}
					]
				]
				write/lines/append outputfile ""
				print ""
			]
		]
	]
]
;/*}}}*/
; Une fois tout écrit, on ferme les balises ouvertes:/*{{{*/
write/append outputfile to-string [
{
</body> 
</html>
}]

;/*}}}*/
;}}}
;];}}}

print rejoin ["Report generated: " to-string outputfile]
browse outputfile

