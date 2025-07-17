# NWT
FS 2025 balance sheet

### Known Issues
- Animal values are not accurate if health < 100% 
- Horse values are not accurate 
- Fill currently in leased vehicles is not incuded in fill calcuations

### Implementaion Details
Produces a menu tallying the total value of a users farm. Entries are not included if they are for an amount equal to 0.

The types of entries:
  - Fill : Fill is any inventory for the user. Value is dictated by the item types `pricePerLiter` configuration. Entries are agregated.
     - Placeables fill amounts and placeable mods will be included if the following specs are supported: 
        - `spec_silo` if included in`getFillLevels()`
        - `spec_siloExtension` if included in `storage.fillLevels`
        - `spec_husbandry` if included in `storage.fillLevels`
        - `spec_manureHeap` if included in `manureHeap.fillLevels` 
        - `spec_bunkerSilo` please see implementation for details
     - Vehicle fill amounts will be included if owned by the player. Vehicle Mod's fills will be included if `spec_fillUnit.fillUnits` is supported
     - Bales are included if registered and the objects are `Bale`
     - Production's fills are incuded if it is included in `productionChainManager.productionPoints` and is included in `production.outputFillTypeIdsArray` and `production.storage:getFillLevel()`
  - Livestock : Livestock owned by the user. The value is _roughly_ modeled based on the sell price of the animal (idk how to get it accurately, pls create a PR if you know). Livestock is agregated by placeable
    - Placeable Mods will be supported to include livestock if `spec_husbandry` is included
    - Livestock Mods will be supported if `spec_husbandry.clusterSystem.clusters` and `animalSystem.subTypes[].sellPrice:get()` are supported 
  - Equipment : Vechiles owned by the user. Value is the sell price of the equipment. Vehciles are not agregated
    - Mods will be supported if `vehicle:getSellPrice()` and `vehicle.typeName` are supported
  - Farmland : Farmland owned by the user. Value is the sell price of the farmland. Farmland is not agregated
    - Mods will be supported if `farmland.price` is supported
  - Placeables : Placeables owned by the user. Value is the sell price of the placeable. Placeables are not agregated
    - Mods will be supported if `placeable:getSellPrice()` is supported
  - Cash : Cash in users account.
  - Loan : Amount of loan taken out by the user. This is natively agregated by the loan system.
    - Mods to the loan system are currently not supported

### TODO
- [ ] test pallet, bale, and root crop storages
- [ ] change menu icon 
- [ ] remove debug statements
