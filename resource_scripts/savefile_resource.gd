extends Resource
class_name SaveFile

## The filename associated with the save file. When not set to anything, defaults to whatever USAPI's save path is set to + current timestamp; user file path may be anonymized if so.
@export var fileName := ""

## The data associated with this save file.[br][br][b]It is strongly recommended you do not edit this in the editor.[/b]
@export var data := {}

## Timestamp of when this SaveFile was constructed.[br][br]Format: yyyymmdd[br][br]
@export var timeCreated := 19990101

## Unique save slot ID. Depending on how you use USAPI to handle save slots, you might never need to use this, or this will be a living nightmare for you.[br][br]Let's be honest here, this is more complicated than it should be.
@export var uniqueID := 0

## Determines if the SaveFile can be edited or not.
@export var canEdit := true

