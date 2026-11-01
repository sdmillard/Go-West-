param([string]$Godot = "$PSScriptRoot/.tools/godot/Godot_v4.5.1-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) {
    $resolved = Get-Command godot -ErrorAction SilentlyContinue
    if (-not $resolved) { throw 'Pass -Godot with the path to a Godot 4.5.1+ executable.' }
    $Godot = $resolved.Source
}
# Keep test runtime files local to the project.
$env:APPDATA = Join-Path $PSScriptRoot '.tools/userdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
$importOutput = & $Godot --headless --path $PSScriptRoot --editor --import 2>&1
if ($LASTEXITCODE -ne 0 -or ($importOutput -match 'SCRIPT ERROR:|ERROR:')) {
    $importOutput | Write-Output
    throw 'Godot asset import failed'
}
foreach ($suite in @('tests/test_simulation.gd', 'tests/test_route.gd', 'tests/test_art.gd', 'tests/test_ui.gd', 'tests/test_motion.gd', 'tests/test_health.gd', 'tests/test_survival.gd', 'tests/test_hunting.gd', 'tests/test_provisions.gd', 'tests/test_preservation.gd', 'tests/test_oxen.gd', 'tests/test_trail_context.gd', 'tests/test_care_combat.gd', 'tests/test_camp_rest.gd', 'tests/test_party_character.gd', 'tests/test_party_framework.gd', 'tests/test_party_setup.gd', 'tests/test_party_flaws.gd', 'tests/test_character_catalog.gd', 'tests/test_crime.gd', 'tests/test_companions.gd', 'tests/test_remains.gd', 'tests/test_party_benefits.gd', 'tests/test_historical_economy.gd', 'tests/test_departures.gd', 'tests/test_walking.gd', 'tests/test_saves.gd', 'tests/test_graves.gd', 'tests/test_full_trail.gd', 'tests/test_journey_policy.gd', 'tests/test_winter.gd', 'tests/test_meat_accounting.gd', 'tests/test_working_team_policy.gd', 'tests/test_disease.gd', 'tests/test_climate.gd', 'tests/test_branches.gd', 'tests/test_field_actions.gd', 'tests/test_social.gd', 'tests/test_appearance.gd', 'tests/test_recruitment.gd', 'tests/test_ribbon.gd', 'tests/test_local_targets.gd', 'tests/test_inventory.gd', 'tests/test_discards.gd', 'tests/test_news.gd', 'tests/test_wanted.gd', 'tests/test_detention.gd', 'tests/test_leader_death.gd', 'tests/test_produce.gd', 'tests/test_current_policy.gd', 'tests/test_bandit_demands.gd', 'tests/test_return_travel.gd', 'tests/test_wagon_trade.gd', 'tests/test_wagon_guards.gd', 'tests/test_wagon_sale_display.gd', 'tests/test_robbery_demands.gd', 'tests/test_mounts.gd', 'tests/test_horse_trade.gd', 'tests/test_horse_country.gd', 'tests/test_horse_flight.gd', 'tests/test_mount_campaign.gd', 'tests/test_emergency_travel.gd', 'tests/test_animal_work_balance.gd', 'tests/test_nutrition_pack_recovery.gd', 'tests/test_wage_autopay.gd', 'tests/test_companion_tasks.gd', 'tests/test_camp_repair_guard.gd', 'tests/test_field_outings.gd', 'tests/test_horse_loads.gd', 'tests/test_hunting_balance.gd', 'tests/test_hunt_time.gd', 'tests/test_coordinated_camp.gd', 'tests/test_mobile_camp.gd', 'tests/test_repeat_hunts.gd', 'tests/test_food_energy.gd', 'tests/test_fishing.gd', 'tests/test_fishing_audit.gd', 'tests/test_seasonal_fish.gd', 'tests/test_livestock.gd', 'tests/test_livestock_balance.gd', 'tests/test_table_meals.gd', 'tests/test_livestock_feeding.gd', 'tests/test_feeding_comparison.gd', 'tests/test_egg_progress.gd', 'tests/test_hen_sharing.gd', 'tests/test_ruminant_nutrition.gd', 'tests/test_shared_pasture.gd', 'tests/test_dairy_balance.gd', 'tests/test_farmer_mastery.gd', 'tests/test_scurvy_trace.gd', 'tests/test_partial_scurvy.gd', 'tests/test_vitamin_reserves.gd', 'tests/test_pelts.gd', 'tests/test_trail_income.gd', 'tests/test_income_comparison.gd', 'tests/test_income_followup.gd', 'tests/test_work_crews.gd', 'tests/test_leathercraft.gd', 'tests/test_crew_craft_audit.gd', 'tests/test_fixed_hide.gd', 'tests/test_infection.gd', 'tests/test_disease_clocks.gd', 'tests/test_dogs.gd', 'tests/test_rafting.gd', 'tests/test_wagon_train.gd', 'tests/test_native_encounters.gd', 'tests/test_native_contact_stories.gd', 'tests/test_native_contact_expansion.gd', 'tests/test_native_justice.gd', 'tests/test_weapons.gd', 'tests/test_jailbreak.gd', 'tests/test_tactical_combat.gd', 'tests/test_profession_skills.gd', 'tests/test_guide_book.gd', 'tests/test_recognition.gd', 'tests/test_river_winter.gd', 'tests/test_cabins.gd', 'tests/test_new_stops.gd', 'tests/test_applegate.gd')) {
    $output = & $Godot --headless --path $PSScriptRoot --script $suite 2>&1
    $code = $LASTEXITCODE
    $output | Write-Output
    if ($code -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|FAIL:|FAIL UI:')) {
        throw "Godot suite failed: $suite"
    }
}










