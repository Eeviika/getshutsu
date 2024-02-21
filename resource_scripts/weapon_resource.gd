extends Resource
class_name Weapon

@export_category("Weapon Metadata")
## The name of the weapon. This is displayed to the player.
@export var displayName: String = "Weapon"
## The ID of the weapon. If left blank, will convert the displayName to use as an ID instead.
@export var weaponID: StringName = "weapon_id"
## The weapon's type. This determines how it is used when the ATTACK action is used.
@export_enum ("GunRapid", "GunSingle", "GunSpread", "Melee") var weaponType: String = "Melee"
## The weapon's rarity. This is used internally to determine how this weapon is spawned, but is also visible to the player.[br][br][i]Shiny weapons only spawn on Hardcore.[/i]
@export_enum ("Common", "Uncommon", "Rare", "Very Rare", "Shiny") var rarity: int = 0
## How much damage the weapon deals. Must be >= 1. Weapons that deal 0 damage are considered "broken".
@export var damage: int = 1
## How fast the weapon fires. [br][br][i]If weaponType is melee, this is treated as a multiplier rather than the actual speed.[/i]
@export var fireRate: int = 5

@export_group("Melee Options")
## How the melee weapon should be used. Swing makes a large AOE damage area, while Stab, quite literally, stabs whatever the player is looking at.[br][br][b]This does nothing if the type is not Melee![/b]
@export_enum ("Swing", "Stab") var meleeType: String = "Stab"
## The range the weapon has. Dependent on meleeType.[br][br]The higher the range for swing, the bigger the AOE.[br][br]For stab, the farther away an enemy can be and still take damage (so long as you're looking at them).[br][br][b]This does nothing if the type is not Melee![/b]
@export var meleeRange: int = 0

@export_group("Gun Options")
## How much ammo is in one mag at once.[br][br][b]This does nothing if the type is not a gun type![/b]
@export var gunMagSize: int = 0
## How fast bullets travel (doesn't affect damage or collisions).[br]This is a multiplier to the base bullet speed.[br][br][b]This does nothing if the type is not a gun type![/b]
@export var bulletSpeed: int = 1
## How long it takes to reload the gun after emptying the mag.[br]This is a multiplier to the base reload speed.[br][br][b]This does nothing if the type is not a gun type![/b]
@export var reloadSpeed: int = 1