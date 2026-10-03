# SurvivorQuest: Godot 4 Survivors-like Web Game Starter

A modular, production-ready 2D Survivors-like / Bullet Heaven game scaffold for **Godot 4**, optimized for web exports to portals like **CrazyGames**, **Poki**, and **itch.io**.

---

## Architecture Overview

```
survivors-game/
├── project.godot               # Godot 4 project config (GL Compatibility for web, 1280x720)
├── setup_godot.sh              # 1-click script to download & configure Godot 4.3 on Linux
├── export_web.sh               # 1-click script to package HTML5 release zip
├── export_presets.cfg          # Web export configuration
├── generate_sounds.py          # Pure Python 8-bit retro sound synthesizer
├── scripts/
│   ├── ad_manager.gd           # CrazyGames / Poki JavaScriptBridge & Editor simulator
│   ├── sound_manager.gd        # Audio pool with pitch variance
│   ├── floating_text.gd        # Bouncing damage numbers
│   ├── camera.gd               # Player tracking & screen shake
│   ├── game_manager.gd         # Run lifecycle, scoring, high scores, meta-gold persistence
│   ├── player.gd               # 8-way movement, health, XP leveling, magnet pickup
│   ├── weapon.gd               # Nearest-enemy auto-targeting & projectile spawner
│   ├── projectile.gd           # Pierce, damage, speed, collision
│   ├── orbiting_weapon.gd      # Rotating shields (King Bible / Garlic style)
│   ├── orbiting_shield.gd      # Orbiting damage blade satellite
│   ├── enemy.gd                # Swarm movement, contact damage, XP gem drop
│   ├── enemy_spawner.gd        # Dynamic wave scaling around camera perimeter
│   ├── gem.gd                  # Magnetic acceleration to player on pickup
│   ├── upgrade_manager.gd      # Level-up card selection & game pause controller
│   └── hud.gd                  # HP/XP bars, run timer, kills, Game Over ad hooks
├── assets/
│   └── audio/                  # Generated 16-bit retro WAV sound effects
│       ├── shoot.wav
│       ├── hit.wav
│       ├── gem.wav
│       ├── level_up.wav
│       └── hurt.wav
└── scenes/
    ├── main.tscn               # World scene containing Player, Spawner, HUD, Upgrades
    ├── player.tscn             # Player node with MagnetArea, Weapon, OrbitingShield
    ├── weapon.tscn             # Auto-aim weapon node
    ├── projectile.tscn         # Flying projectile
    ├── orbiting_weapon.tscn    # Rotating satellite manager
    ├── orbiting_shield.tscn    # Orbiting shield blade
    ├── enemy.tscn              # Swarm enemy
    └── gem.tscn                # Collectible XP gem
```

---

## Monetization Integrations (Web Portals)

The game includes built-in hooks in [ad_manager.gd](file:///home/renovibe79/survivors-game/scripts/ad_manager.gd) for high-earning ad placements:

1. **"Second Chance" Revive (Rewarded Ad)**:
   * When player dies, they can click "📺 Watch Ad to Revive" to regain 60% HP and keep their run alive.
2. **"Double Gold" Multiplier (Rewarded Ad)**:
   * Multiplies collected run coins for meta-upgrades.
3. **Midroll Interstitial**:
   * Automatically triggered when restarting or returning to menu.

*Note: In the Godot Editor or desktop builds, `AdManager` automatically simulates an ad watch so you can test rewards without web SDK errors.*

---

## Expansion 10.0: Võ Lâm & Dragon Legend Edition

Inspired by **Võ Lâm Truyền Kỳ** (Swordsman Online / JX Online) and **Dragon Legend Online**:

1. **Long Hồn (Dragon Soul Awakening)**:
   - Slaying monsters charges the sacred **Long Hồn** gauge (+2 standard, +12 champion, +15 goblin, +35 boss).
   - Press <kbd>R</kbd> or tap the HUD Dragon Button at 100% charge to trigger **Kim Long Thần Giáng (Celestial Dragon Awakening)**.
   - Transforms the hero into a majestic Golden Dragon for 8.5 seconds:
     - Complete invulnerability and aerial flight over enemy swarms.
     - +65% Movement Speed with custom wing-flapping procedural animations.
     - Continuous **Dragon Breath / Giáng Long Thập Bát Chưởng** torrent scorching all nearby foes for heavy damage and Fire Burn.

2. **Hệ Thống Ngũ Hành (Five Elements Combat & Status Procs)**:
   - **Hỏa (Fire)**: Fireballs and Dragon Breath inflict Burn DoT with fiery damage ticks.
   - **Mộc (Wood)**: Projectiles inflict Poison DoT with toxic green damage ticks.
   - **Thủy (Water)**: Frost Stasis and cold spells inflict Slow and Freeze, immobilizing mobs.

3. **High-Density Swarm Performance (v9.1 / v10.0)**:
   - Circular object pool for floating combat text (zero allocation spikes).
   - Distance-squared contact culling and off-screen animation LODs maintaining 60 FPS under massive swarms.

---

## Expansion 11.0: Linh Thú Companions & Hệ Thống Kinh Mạch (Meridian Cultivation)

Deepening player retention and authentic Eastern martial-arts MMORPG progression inspired by **Võ Lâm Truyền Kỳ** and **Dragon Legend Online**:

1. **Linh Thú Companions (Thần Thú Đồng Hành)**:
   - **Tiểu Kim Long (Dragon Whelp)**: Ranged Chi orb projectile attacks + 40% chance of Fire Burn DoT. Features custom procedural wing-fluttering flight physics.
   - **Bạch Hổ Thần Thú (White Tiger)**: Ferocious melee pounce attacks dealing high single-target physical damage.
   - **Linh Thú Magnetic Vacuum**: Automatically vacuums distant XP gems and gold coins within a 175px radius, drawing them straight to the hero.
   - Dynamic companion selection in the Meta Shop; levels up alongside the hero (+4 damage per level).

2. **Hệ Thống Kinh Mạch (Meridian Cultivation / Bát Mạch Chân Khí)**:
   - Permanent wuxia cultivation upgrades in the Meta Shop:
     - **Nhâm Mạch (Ren Meridian - Khí Thuẫn)**: Creates an absorbing **Qi Shield** (`☯️ Khí Thuẫn`) that completely shields hero HP from damage and passively regenerates out of combat.
     - **Đốc Mạch (Du Meridian - Bạo Kích)**: Grants +5% Critical Strike Chance per cultivation rank.
     - **Xung Mạch (Chong Meridian - Thân Pháp)**: Increases hero movement swiftness (+12 px/s per rank).
     - **Đan Điền (Dantian - Khí Hải)**: Expands the inner spirit pool, boosting Long Hồn (Dragon Soul) harvest rate by +30% per rank.

3. **Meta Shop & HUD Integration**:
   - Live Qi Shield display on HUD TopBar: `%d/%d HP [☯️%d]`.
   - "Tu Luyện Kinh Mạch" cultivation altar & "Linh Thú Đồng Hành" sanctuary added to Meta Shop.
   - Dual-layer web (localStorage) and desktop (ConfigFile) persistence for seamless save continuity.

---

## Expansion 12.0: Võ Học Bí Tịch & Thất Long Châu (Martial Arts Scrolls & Seven Dragon Pearls)

An epic fusion of classic **Võ Lâm Truyền Kỳ** secret sect kung-fu manuals and **Dragon Legend Online** Dragon Pearl summoning:

1. **Thất Long Châu (Seven Dragon Pearls & Shenron Summoning)**:
   - Slaying Champions, Bosses, and opening golden chests yields rare glowing **Dragon Pearls** (`Long Châu [1/7] ... [7/7]`).
   - Tracked live on the HUD TopBar via a 7-star celestial pearl tray (`[⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐]`).
   - Gathering all 7 pearls summons the majestic **Thần Long (Divine Shenron)**, opening the **Thần Long Giáng Thế** wish modal:
     - 💰 **Ước Nguyện 1: Kim Sơn Bạc Hải (Mountain of Gold)**: Grants +1,500 Meta Gold immediately + 30-second Golden Frenzy (all enemies drop x2 gold).
     - ☯️ **Ước Nguyện 2: Bất Tử Chân Thân (Invincible Immortal)**: +100 Max HP, +50 Qi Shield, fully restores HP/Qi, and grants a bonus Phoenix Rebirth.
     - ⚔️ **Ước Nguyện 3: Vạn Kiếm Quy Tông (Ten Thousand Flying Swords)**: Unleashes a relentless 20-second celestial storm of homing flying spirit swords piercing screen-wide enemy hordes.

2. **Võ Học Bí Tịch (Ancient Martial Arts Secret Scrolls)**:
   - Unique drop scrolls from Elite Champions and Bosses granting permanent in-run martial arts:
     - 📜 **Dịch Cân Kinh (Shaolin Yi Jin Jing)**: Every 7.5s unleashes a booming **Sư Tử Hống (Lion's Roar)** golden Buddhist gong shockwave dealing 80 damage, stunning, and pushing all surrounding foes back.
     - 🗡️ **Lục Mạch Thần Kiếm (Dali Six Meridian Divine Swords)**: Automatically fires rapid piercing finger-Qi laser spirit sword beams every 0.65s (35 damage, pierces 3 targets).
     - ☯️ **Thái Cực Kiếm Trận (Wudang Tai Chi Domain)**: Envelops the hero in a spinning Taoist Yin-Yang aura that slows surrounding enemies by 50% and damages them continuously.

---

## Expansion 13.0: Game Feel & Retention Masterclass (FTUE & Wuxia Juice)

Focused on elevating day-1 retention, player comprehension, and audiovisual satisfaction:

1. **Tân Thủ Nhập Môn (First-Time User Experience Onboarding)**:
   - Non-intrusive onboarding pill banner displayed on initial run (`is_first_run` persisted across Web `localStorage` and desktop `save_data.cfg`).
   - Teaches core loop: 8-way movement / touch drag, auto-targeting martial arts, and collecting 7 Dragon Pearls.
   - Automatically fades away upon scoring 3 kills or manual acknowledgement.

2. **Visual Tension (Low-HP Danger Vignette)**:
   - Full-screen crimson danger vignette activates whenever hero health drops into critical danger ($\le 25\%$ HP).
   - Alerts player to disengage, pop active defensive skills, or harvest healing shrines.

3. **Crystalline Qi Shield Shatter**:
   - Synthesized resonant glass-shattering sound effect (`shield_break.wav`) paired with intense camera impact trauma whenever Nhâm Mạch Qi Shield is completely depleted.

4. **Thần Long Celestial Flash**:
   - Full-screen luminous golden flash (`celestial_flash`) accompanied by a majestic dragon roar upon picking up the 7th Dragon Pearl, giving the Shenron summon maximum audiovisual punch.

5. **Dynamic Combat BGM (Wuxia War Drums)**:
   - Dynamic sound system seamlessly shifts into high-tempo war drum battle music (`boss_bgm.wav`) when a Boss appears or a Blood Moon Eclipse begins.
---

## Expansion 14.0: Đại Hội Võ Lâm (Global Martial Tournament & Daily Celestial Trial)

Introduces asynchronous social competition, daily player retention hooks, and the 5th playable sect hero:

1. **Đại Hội Võ Lâm (Hall of Fame Martial Tournament)**:
   - Competitive asynchronous leaderboard pre-populated with 10 legendary Jin Yong martial arts masters:
     - 🥇 *Tiêu Phong* (Cái Bang Bang Chủ - 68,500 pts)
     - 🥈 *Vô Danh Thần Tăng* (Thiếu Lâm Tàng Kinh Các - 59,200 pts)
     - 🥉 *Trương Tam Phong* (Võ Đang Chưởng Môn - 51,400 pts)
     - *Đông Phương Bất Bại, Lệnh Hồ Xung, Dương Quá, Quách Tĩnh, Hoàng Dung, Đoàn Dự, Hư Trúc*.
   - Customizable player nickname persisted to browser `localStorage` and desktop `leaderboard_data.cfg`.
   - Balanced scoring algorithm: $\text{Score} = (\text{Time} \times 12) + (\text{Kills} \times 28) + (\text{Gold} \times 2) + (\text{Scrolls} \times 2,500)$.
   - Accessible from the TopBar (`🏆 VÕ LÂM (L)`), Pause Menu, and automatically on Game Over with celebratory fanfare (`fanfare.wav`) upon placing into the Top 10.

2. **Thử Thách Hằng Ngày (Daily Seeded Celestial Trial)**:
   - Calendar-date seeded deterministic daily mutator rotation offering massive meta-gold bounties:
     - 🔥 **Hỏa Diệm Sơn Khí**: +50% Fire damage, +20% mob speed (+600 Gold).
     - 🛡️ **Kim Cương Bất Hoại**: x2 Qi Shield capacity, x2 Champion spawn rate (+750 Gold).
     - ⚔️ **Vạn Kiếm Quy Tông**: -30% cooldowns, +40% mob density (+800 Gold).
     - 🍶 **Bát Tiên Túy Võ**: +25% Dodge chance, x3 Treasure Goblins (+900 Gold).
   - Tracks daily completion status, high scores, and midnight calendar resets.

3. **5th Playable Hero: Cái Bang Đệ Tử (Tiêu Lãng - Beggar Sect)**:
   - Custom character sprite wielding green bamboo staff and yellow wine gourd (`hero_beggar.png`).
   - Innate Sect Trait: **Lăng Ba Vi Bộ (+15% Dodge Chance)** to completely negate incoming damage with floating `NÉ ĐÒN!` feedback.
   - Active Skill: **Say Rượu Bát Tiên (Drunken Brew)** (Space / Skill button):
     - Takes a hearty swig of wine (`wine_drink.wav`), entering a 6-second drunken trance.
     - +40% Dodge Chance (reaching 55%+ total evasion), +50% Attack Speed, golden aura, and drunken sway movement.

---

## Expansion 15.0: Võ Lâm Tuyệt Kỹ & Bí Cảnh Luân Hồi (The Wuxia Codex of Unlocks & Demonic Risk-Reward Curses)

Addresses long-term player retention, emergent build crafting, and high-stakes risk/reward gameplay:

1. **Bảng Phong Thần Võ Lâm (The Wuxia Unlock Codex)**:
   - Eliminates generic stat inflation by introducing 8 game-altering milestone quests with immediate visual & mechanical rewards:
     - 🥋 **Sơ Xuất Giang Hồ**: Survive 3 minutes $\rightarrow$ +15 Permanent Move Speed for all heroes.
     - 💀 **Trảm Yêu Trừ Ma**: Slay 500 cumulative enemies $\rightarrow$ +600 Meta Gold bounty.
     - 👹 **Diệt Tuyệt Ma Vương**: Slay 1 Boss or Behemoth $\rightarrow$ Unlocks Relic: **Bát Tiên Hồ Lô** (Drunken Gourd: triggers holy wine splash dealing 120 AoE damage on every successful dodge).
     - 🐉 **Thất Tinh Quy Vị**: Collect 7 Dragon Pearls $\rightarrow$ **Thần Long Lệnh** (Start every new run with 1 Dragon Pearl already gathered).
     - 🩸 **Ma Đạo Huyết Khế**: Sign 1 Demonic Pact $\rightarrow$ Unlocks Relic: **Tà Ma Lệnh Bài** (+25% Crit Damage and +15% Attack Speed when below 50% HP).
     - 🌑 **Huyết Nguyệt Tắm Máu**: Survive an entire Blood Moon $\rightarrow$ Unlocks Relic: **Huyết Ma Kiếm** (4% Life-Steal on hit).
     - ⚔️ **Vạn Địch Bất Bại**: Slay 1,500 enemies in a single run $\rightarrow$ +20% Attack Speed across all weapons.
     - 💰 **Vạn Tiền Đại Phú**: Accumulate 2,500 Meta Gold $\rightarrow$ **Kim Thiềm Thần Thú** (+30% coin value drop multiplier).
   - Dynamic in-run toast banner alert (`🏆 THÀNH TỰU MỞ KHÓA`) accompanied by celebratory harp chime (`quest_complete.wav`).
   - Accessible via TopBar (`📖 THÀNH TỰU (Q)`), shortcut key `Q`, Pause Menu, and Game Over Screen.

2. **Tế Đàn Tà Thần (Demonic Altars of Risk & Reward)**:
   - Interactive obsidian altars placed across the world emitting crimson rune particles.
   - Interactive pact modal offering 3 Faustian bargains with deep survival trade-offs:
     - 🩸 **Ma Đạo Huyết Khế (Blood Covenant)**: Sacrifices 35% Current HP & takes +20% extra damage $\rightarrow$ +45% Might permanently and restores +4 HP per hit.
     - 👹 **Tà Khí Đồ Sát (Abyssal Frenzy)**: Enemies gain +30% move speed and spawn rate surges by +40% $\rightarrow$ Drops 2x XP and 2x Gold across all monsters.
     - 🚫 **Vạn Cổ Độc Cô (Hermit's Sacrifice)**: Qi Shield is permanently sealed to 0 $\rightarrow$ Instantly grants an Ancient Relic Chest + 500 Gold.
   - Distinct ominous invocation sound effect (`curse_pact.wav`).

3. **Băng Hỏa Bạo Kích (Explosive Thermal Shockwave Synergy)**:
   - Introduces multi-elemental reaction mechanics: applying Fire/Burn to a Frozen enemy (or Frost Stasis to a Burning foe) violently detonates a **Thermal Shockwave** dealing 140 instant AoE damage in a 130px radius with screen shake and `💥 BĂNG HỎA BẠO KÍCH!` visual popups.

---

## Expansion 16.0: Kỳ Ngộ Giang Hồ, Đỉnh Hoa Sơn Tuyết Phủ & Hoàng Kim Trang Bị

1. **Chiến Trường Mới: Đỉnh Hoa Sơn Tuyết Phủ (Mount Hua Frost Summit)**:
   - Dynamic stage selector with custom snowy ground textures (`snow_floor.png`).
   - Periodic Blizzard hazard: Sweeps across the summit, chilling non-immune heroes with a 25% movement slow while amplifying frost weapon damage by +50%.
2. **Kỳ Ngộ Giang Hồ: Ẩn Sĩ Cao Nhân (Secret Hermit NPC & Traveling Shop)**:
   - Legendary wuxia hermit randomly wanders onto the battlefield offering 3 miraculous elixir draughts:
     - 🍶 **Cửu Chuyển Hoàn Hồn Đan**: Instant full heal + 20% max HP shield.
     - ⚡ **Thiên Sơn Tuyết Liên**: Permanent +15% move speed & immunity to environmental hazards.
     - 🥋 **Bồ Đề Tâm Pháp**: Grants +1 level to all equipped weapons immediately.
3. **Hoàng Kim Trang Bị (Equippable Martial Gear)**:
   - ⚔️ **Ỷ Thiên Kiếm (Weapon Slot)**: +25% attack radius & +15% damage.
   - 🛡️ **Nhuyễn Vị Giáp (Armor Slot)**: +2 flat armor & reflects 40% damage back to attackers.
   - 🥾 **Vân Hạc Hài (Boots Slot)**: +30 move speed & complete immunity to slows.

---

## Expansion 17.0: Visual Overhaul, Atmospheric Polish & Cinematic Main Menu (Đại Tu Thị Giác Toàn Diện)

1. **Cinematic Title Screen / Main Menu (Sảnh Chờ Huyền Thoại Võ Lâm)**:
   - **Hero Showcase**: Live breathing idle animation of the selected hero, displaying innate archetype traits, weapons, and quick class swap button `[C]`.
   - **Stage Badge**: Real-time battlefield display with map switcher `[M]`.
   - **Glowing CTA Button**: `[ ⚔️ XUẤT TRẬN / START RUN (SPACE) ⚔️ ]` with pulsing scale animation and keyboard hotkey support (`SPACE` / `ENTER`).
   - **Meta Progression Deck**: One-click direct access to Heroes `[C]`, World Map `[M]`, Leaderboards `[L]`, Codex `[Q]`, and Blacksmith Shop.
   - **Seamless Return Flow**: `[ 🏠 Về Menu Chính / Return to Main Menu ]` integrated into Pause Menu and Game Over Screen.
2. **Dynamic Soft Dual-Layer Drop Shadows**:
   - Zero-texture, resolution-independent vector ellipse drop shadows on Player, Enemies, Companions, Gems, and Coins, grounding characters into the world.
3. **Combat Crunch & Punchy Juice**:
   - **Pure White Hit-Flash**: Saturated `Color(4.0, 4.0, 4.0)` flash on damage impact.
   - **Squash-and-Stretch Recoil**: Dynamic sprite recoil on hit restoring with back ease.
   - **Soul Flame Death Particles**: Colorful multi-directional soul flame explosion on mob defeat.
   - **Kinetic Loot Pop Physics**: Gems and Gold Coins arc outward with impulse velocity on spawn before floating.
   - **High-Contrast Floating Damage Text**: Outlined numbers (`outline_size: 4`) with punchy spawn scale pop (`Vector2(1.35, 1.35) -> Vector2(1.0, 1.0)`).
4. **Cinematic Vignette & Stage-Adaptive Weather**:
   - Zero-shader 512x512 radial gradient vignette overlay framing gameplay.
   - Stage-adaptive ambient weather particle system:
     - **Ba Lăng Huyện**: Drifting golden leaves and wind motes.
     - **Đỉnh Hoa Sơn**: Swirling mountain blizzard snowflakes.

---

## Expansion 18.0: "Thiên Hạ Đệ Nhất: The 8-Minute Climax Run & Martial Synergy Matrix"

1. **8-Minute Web Climax Roadmap & Demon Emperor Final Boss (Cửu Trùng Đăng Tiên)**:
   - Fixed the 150-second content cliff with an 8-minute (480s) wave roadmap designed for web gaming retention:
     - `180s (3:00)`: Swarm 3 (*Thi Ma Trận* - Armored Skeletal Legion).
     - `210s (3:30)`: Goblin 3 (*Kim Tiền Thử Đại Hỉ* - High-speed treasure runner).
     - `240s (4:00)`: Swarm 4 (*Vu Độc Ma Trận* - Necromancer Cult casting dark magic).
     - `270s (4:30)`: Blood Moon Eclipse 2 (30s duration - 2x XP & Gold surge).
     - `300s (5:00)`: Boss 3 (*Song Thủ Ma Tướng* - Reinforced Behemoth Vanguard).
     - `360s (6:00)`: Hermit Encounter 2 (*Kỳ Ngộ Đỉnh Phong: Lão Ngoan Đồng* - Late-game elixir upgrades).
     - `390s (6:30)`: Apocalypse Swarm (*Vạn Ma Vây Hãm* - 32-mob siege with 25% champion affix rate).
     - `435s (7:15)`: Final Boss (*Hắc Huyết Ma Hoàng* - Demon Emperor with 2,400 HP, multi-phase attacks, radial dark magic waves, and screen-shaking arrival).
2. **True Victory Condition & Ascension Modal (Bảng Vàng Quang Vinh)**:
   - Surviving the full 8 minutes (or slaying the Demon Emperor) triggers a triumphant victory state.
   - Grants **+1,000 Gold Victory Bonus** and submits score to the leaderboard.
   - Unfurls the glowing golden **Victory Screen**:
     - Martial Title honors: *Võ Lâm Minh Chủ*, *Tuyệt Thế Cao Thủ*, or *Thiên Hạ Đệ Nhất Cao Thủ*.
     - Dynamic performance breakdown: Survival time, kill tally, and gold bounty earned.
     - Choices: `[ ♾️ Vô Tận Luân Hồi / Endless Mode ]` (continue pushing into infinite survival) or `[ 🏠 Về Sảnh Chờ / Return to Main Menu ]`.
3. **3-Weapon Slot Cap & Strategic Build Specialization**:
   - Caps total active weapons at **3 slots** (down from unlimited 5), eliminating homogenizing "all weapons every run" syndrome.
   - Once 3 weapon slots are full, new weapon unlock cards (`unlock_*`) are removed from the upgrade pool, focusing late-game choices on weapon rank upgrades, legendary evolutions, and passive stat amplifiers.
4. **Paired Evolutions & Wuxia Catalyst Synergies**:
   - Overhauled evolution cards with paired catalyst requirements and rich Wuxia lore:
     - 👑 **Vô Ảnh Thần Châm** (Thousand Blades): *Phi Đao Lv.5 + Thân Pháp Thần Tốc* $\rightarrow$ 8-blade astral storm 360°.
     - 👑 **Thái Cực Hộ Thể** (Solar Bulwark): *Khiên Bát Quái Lv.5 + Nhâm Mạch Hộ Thể* $\rightarrow$ 5 solar blades spinning at hyperspeed.
     - 👑 **Cửu Thiên Huyền Lôi** (Heaven's Wrath): *Thiên Lôi Lv.5 + Đốc Mạch Bạo Kích* $\rightarrow$ 4 chain-lightning strikes with 100% crit shockwaves.
     - 👑 **Kim Cương Hỏa Chưởng** (Apocalypse Meteor): *Hỏa Cầu Lv.5 + Hỏa Luân Bộc Phá* $\rightarrow$ Giant exploding meteors creating firestorms.
     - 👑 **Càn Khôn Đại Na Di** (Reaper's Cleave): *Đả Cẩu Trận Lv.5 + Dịch Cân Kinh* $\rightarrow$ 3 orbiting scythes with black hole vortex suction.
5. **Thematic Jianghu Unification**:
   - Fully unified all 5 hero archetypes with authentic Jianghu martial sects:
     - **Tiêu Dao Kiếm Hiệp** (Sir Kaelen): Sword mastery & defensive shielding.
     - **Minh Giáo Liệt Hỏa** (Ignis): Scorching pyromancy & explosive AoE.
     - **Đường Môn Cung Thủ** (Zephyr): Toxic evasion & critical needlework.
     - **Nga Mi Cầm Tiên** (Morrigan): Frost crowd control & spiritual stasis.
     - **Cái Bang Đả Cẩu** (Beggar): Staff arts & ferocious dragon soul bursts.

---

## Expansion 18.1: Dialog Trap Fix & Modal UX Hardening (Khắc Phục Toàn Diện Kẹt Cửa Sổ Tiệm Rèn & Thoát Giao Diện)

1. **Tiệm Rèn (Blacksmith Upgrades Shop) Overhaul**:
   - **Root Cause Resolved**: The shop contained 18+ meta-upgrades, meridians, and companions in an unconstrained vertical container exceeding 1,100px on a 720p screen, pushing both the top `[✖]` and bottom `[Done]` close buttons far off-screen.
   - **Bounded 720x560px Modal**: Pinned between $y = -280$ and $+280$ with a smooth vertical `ScrollContainer`.
   - **Fixed Header & Footer Bars**:
     - Top pinned `HeaderBar` with prominent `[✖ ĐÓNG (ESC)]` button.
     - Bottom pinned `BottomBar` with full-width `[✓ HOÀN TẤT / ĐÓNG TIỆM RÈN (ESC)]` button.
   - **Full-Screen Dark Backdrop with Click-to-Close**: Clicking the dimmed overlay outside the shop instantly closes the dialog.
   - **Triple Close Redundancy**: Players can close Tiệm Rèn via ESC key, top-right header button, bottom action bar button, or clicking the backdrop.
2. **Universal In-Game Modal Hardening**:
   - **Tế Đàn Tà Thần (AltarModal)**: Added full-screen backdrop click-to-close, keyboard ESC support, and enlarged `[✖ TỪ CHỐI / RỜI ĐI (ESC)]` button.
   - **Lão Ngoan Đồng (HermitShopModal)**: Added backdrop click-to-close, keyboard ESC support, and `[✖ RỜI ĐI (ESC)]` button.
   - **Thần Long Giáng Thế (ShenronWishModal)**: Added dedicated `[✖ ĐỂ SAU / ĐÓNG (ESC)]` button and enabled ESC dismissal so players are never forced or trapped.
   - **Bảng Phong Thần (CodexModal)**: Wired backdrop click-to-close and ESC key dismiss.
3. **Automated Verification**:
   - Extended `tests/test_menu_closing.tscn` to test all close buttons, backdrop click triggers, and ESC keys across all modals with 100% clean passes.

---

## Expansion 19.0: Combat Skill Expression & Level-Up Mastery (Cửu Kiếm Quy Tông & Tẩy Tủy Quyết)

1. **Directional Sweeping Sword Arc (Độc Cô Cửu Kiếm / Slash Arc)**:
   - Directional melee slash weapon (`scripts/slash_weapon.gd` and `scenes/slash_weapon.tscn`) utilizing `res://assets/textures/slash_arc.png`.
   - Attacks forward along the player's movement direction / facing vector rather than pure auto-aim, rewarding tactical positioning and crowd kiting.
   - Cleaves multiple targets in a 120° sweeping arc with 38 base damage, strong knockback, camera screen shake, and crisp metallic audio (`slash.wav`).
   - Evolves into **Độc Cô Cửu Kiếm Quy Tông (Nine Swords Cleave)** at Lv.5: expands to a massive 180° arc dealing 75 damage on a 0.65s rapid cooldown.

2. **Level-Up Choice Agency (Tẩy Tủy & Bỏ Qua)**:
   - **Tẩy Tủy (Reroll)**: `[ 🎲 TẨY TỦY (REROLL) ]` button with 2 free uses per run (hotkey `R`) to reshuffle the 3 offered upgrade cards when looking for specific build catalysts.
   - **Bỏ Qua (Skip)**: `[ ⏩ BỎ QUA (+30 VÀNG) / SKIP ]` button (hotkeys `X` / `ESC`) that skips card selection in exchange for +30 immediate Gold, cleanly unpausing gameplay without trapping the player.
   - Dedicated keyboard card shortcuts (`[1]`, `[2]`, `[3]`) for rapid, mouse-free level-up selections.

3. **Dodge Invulnerability (I-Frames / Thân Pháp)**:
   - Tactical dash and evasion grant a dedicated 0.25s invulnerability window (`is_invulnerable`) where incoming collision damage from enemies and boss telegraphs is nullified, rewarding twitch reflexes.
   - Fully integrated into `Player.perform_dash()` and active hero skills.

4. **Audio & Juice Polish**:
   - Expanded 16-bar retro battle BGM track (28.4s loop with distinct Verse and Chorus melodies).
   - Crisp synthesized sound effect for directional sword slashes (`slash.wav`).

---

## Expansion 20.0: The Wuxia Visual & Audio Rebirth (Đại Trùng Tu Võ Lâm)

1. **Complete High-Fidelity Wuxia Visual Overhaul**:
   - Replaced flat 32x32 programmer PIL shapes with hand-crafted high-resolution Eastern Martial Arts character art and textures:
     - **Tiêu Dao Kiếm Hiệp (Knight/Swordsman)**: Wuxia wandering swordsman in flowing azure robes with dynamic Qi aura.
     - **Minh Giáo Liệt Hỏa (Pyromancer)**: Crimson martial flame adept in battle vestments with ember particles.
     - **Đường Môn Thích Khách (Ranger)**: Jade-accented poisoned assassin with concealed needles and shadow cloaks.
     - **Nga Mi Tiên Tử (Sorceress/Mage)**: Ethereal celestial priestess with floating silk sleeves and frosty Qi condensation.
     - **Cái Bang Tiêu Lãng (Beggar/Brawler)**: Rugged dragon-fist martial master wielding wine gourds and earth-shattering strikes.
     - **Hắc Huyết Ma Hoàng (Demon Emperor Boss)**: 256x256 demonic wuxia overlord with sweeping horned crown and dark aura.
   - **Ancient Courtyard Arena Floor**: Seamless 256x256 mossy flagstone paving with scattered crimson maple leaves replacing plain green grid tiles.
   - **Cinematic Title Screen**: 16:9 widescreen panoramic Wuxia landscape (`title_bg.png`) with misty bamboo peaks and mountain sanctuaries.
   - **Dynamic Qi Halo & Character Animation**: Integrated pulsing radial Qi aura around heroes and procedural walk-bobbing / breathing animations.

2. **Acoustic Orchestral Wuxia Soundtrack**:
   - Replaced 8-bit synthetic square/sawtooth beeps with authentic physical modeling acoustic synthesis:
     - **Main BGM (`assets/audio/bgm.wav`)**: 16 bars at 126 BPM (30.5s stereo loop) featuring acoustic Karplus-Strong Guzheng (C major pentatonic), soaring Dizi bamboo flute melodies, and resonant Taiko war drums.
     - **Boss BGM (`assets/audio/boss_bgm.wav`)**: 16 bars at 142 BPM (27.0s stereo loop) featuring aggressive Guzheng shredding, rapid Dizi trills, and pounding combat percussion.

3. **Production Deployment**:
   - Built and verified against all 15 automated test suites with 100% clean passes.
   - Deployed directly to itch.io as **Version 20.0** (`locionic/survivorquest:html5`).

---

## Expansion 22.0: Võ Lâm Tín Cận (Stat Integrity & The Relics That Were Only Words)

Two categories of silent bug, both found by reading what the game *promises* against what it *does*: upgrades the player paid for that refunded themselves, and relics the Codex described in full and never implemented.

1. **Run-Scoped Upgrades No Longer Refund Themselves**:
   - `Player.refresh_meta_stats()` rebuilds `max_health`, `move_speed`, `meta_might_bonus` and `crit_chance_bonus` from their bases — and the meta shop is reachable **mid-run** from the pause menu. Anything a run-scoped source wrote straight onto the live stat was therefore erased by the player's next Vitality purchase:
     - Shenron wish **Ước Nguyện 2: Bất Tử Chân Thân** (+100 Max HP), the hermit's **Cửu Chuyển Hoàn Hồn Đan** (+15% Max HP), UpgradeManager's universal **+25 Max HP** card, and all six **Tàng Kinh Các** intermission scrolls (`−20 Máu Tối Đa`, `−15% Máu Tối Đa`, `−15% Tốc Chạy`, `+35% Bạo Kích`, `+30% Sức Mạnh`).
   - Root fix: four run-scoped accumulators (`run_max_hp_bonus`, `run_might_bonus`, `run_speed_mult`, `run_crit_bonus`) plus single-source builders `_base_max_health()` and `_build_might_bonus()`. Every writer now banks its bonus and lets the rebuild include it. Ỷ Thiên Kiếm's `+15% Sức Mạnh` moved into `_build_might_bonus()` for the same reason — it used to be added at the tail of the recompute, so rebuilding without that tail deleted an equipped weapon.

2. **Xung Mạch No Longer Compounds Into a Silent Discount**:
   - The Thân Pháp meridian read `skill_cooldown_max * (1 - xung * 0.08)` — its *own output*. Since `buy_meridian_upgrade()` calls `refresh_meta_stats()` for **every** meridian, buying Đốc Mạch or Đan Điền discounted the hero skill by another 8% each time: ten unrelated purchases left a 2.4s timer off a 5.5s base.
   - Now derived from `skill_cooldown_base`, the character's un-upgraded timer.

3. **Tà Ma Lệnh Bài (Demonic Token) — Previously Described, Never Implemented**:
   - Registered in the Codex with "*Tăng +25% Sát thương chí mạng và +15% Tốc độ đánh khi dưới 50% HP*" and a quest behind it. `grep -rn demonic_token scripts/` found `codex_manager.gd` and nothing else — the crit multiplier was the bare literal `2.2` with no term for it.
   - Now: **+25% crit damage and +15% attack speed below 50% HP**. Both are getters read at the only two places that exist — `enemy.take_damage()`'s single crit roll, and each weapon's single cooldown line — so a weapon bought mid-rage inherits the haste and nothing compounds while the player sits under the threshold.

4. **Huyết Ma Kiếm (Blood Blade) — Previously Described, Never Implemented**:
   - Registered as "*Mọi đòn đánh hồi phục 4% sát thương gây ra thành sinh lực*" and likewise inert. Now **4% lifesteal**, banked beside the shop and character lifesteal in the one place that reads it.

5. **Automated Verification**:
   - `tests/test_expansion_22.gd` covers all four halves. Each regression is proven non-vacuous: reverting any one fix makes its own checks fail. The suite pins the Storm Amulet and Lôi Hỏa Liên Hoàn off-hits, because both fire inside `take_damage()` and a prior suite persists `collected_relics` to `user://save_data.cfg` — without the pin this suite measures the save file of whoever ran the sweep first.
   - Full gate: **27/27 suites clean** via `./scripts/ci.sh`.

---

## Expansion 23.0: Tách Kỹ Thuật (Buffs You Could Turn Off But Never Could Turn Off)

The same audit shape as 22.0, one layer up: a stat field with **more than one writer and a single reset**. Whichever writer touched it last silently deleted whichever writer went quiet — and no error, no log, no number on screen moved.

1. **The Glacial Champion's Slow Was a One-Way Door**:
   - A `glacial` champion inside its 170px aura ran `player.speed_multiplier = min(player.speed_multiplier, 0.65)` every frame. The only thing that ever set `speed_multiplier` back to `1.0` was the Wind Surge's own timer, which is `0.0` unless the player had taken that landmark — so for everyone else, **one brush past a champion cost 35% of their move speed for the rest of the run**.
   - The `min()` compounded it: standing near a champion while a Wind Surge was live replaced `1.5` with `0.65` rather than composing with it, and the surge's own expiry then reset both to `1.0`.
   - Now a **lease**: the champion refreshes `glacial_slow_timer` while the player is inside the aura, the player decays it. A champion can hold an aura but cannot un-hold it, so the speed comes back on its own when the player walks away or kills it. `speed_multiplier` is once again owned solely by `apply_speed_buff()`.

2. **Four Writers of `might_multiplier`, One Reset**:
   - `apply_might_buff()` assigned it; Huyết Khế added `+0.45`; Tẩy Tủy Hoán Cốt added `+0.20`; the Berserker Brand wrote `max(_, 1.50)`. Only the Might Surge's timer ever reset it. So a surge landing on the Blood Covenant and expiring 25 seconds later **deleted the covenant**, and `max(1.45, 1.50)` threw the covenant's `0.45` away the moment the relic woke.
   - The Brand also never gave its `1.50` back — only the sprite tint was restored in the `elif`.
   - Now: the two permanent pacts bank into `might_flat_bonus` (additive off a `1.0` base), and the Brand became a getter folded into `get_might_multiplier()`. It lifts the player to at least `1.5x` **on top of** what they already had, and stops applying the frame they heal past 40% HP.

3. **Đốc Mạch's Advertised Crit Damage Now Exists**:
   - The meridian table has read "*+7% Crit Chance & +35% Crit DMG per level*" since the Codex shipped. Only the first half was applied — the crit multiplier was the bare `2.2` literal in `enemy.take_damage()`.
   - Now wired through `get_crit_damage_multiplier()`, additive with the Tà Ma Lệnh Bài rage rather than replacing it.

4. **Two Hermit Pacts That Announced Rewards And Delivered Nothing**:
   - `apply_demonic_pact()` looked the spawner up in the group `"spawner"`. `EnemySpawner` registers as **`"enemy_spawner"`**, so the lookup was always `null` — and the Hạ Hạ Quẻ branch then guarded on `spawn_specific_enemy()`, a method no one had ever written. A 30% Hạ Hạ Quẻ roll announced two demons and spawned nothing: the worst possible outcome to roll.
   - Added `EnemySpawner.spawn_specific_enemy(id, pos)` over a small `NAMED_ENEMIES` map (the caller only has a group handle, never the exported `PackedScene`s). It is the same shape the caller already expected, so the pact bodies needed only the group name corrected.

5. **Wave Swarms Now Scale Like Every Other Spawn**:
   - `trigger_swarm()` built its enemies straight from the scene, skipping both the `+floor(difficulty * 0.22)` curve and the danger tier that `spawn_enemy_wave()` applied two functions above it. A wave-5 bat swarm was a wave-0 bat swarm.
   - Both paths now route through one `_scale_for_wave()` — a net deletion, not an addition.

6. **Automated Verification**:
   - `tests/test_expansion_23.gd` covers all five. Each regression is proven non-vacuous: reverting any one fix makes its own checks fail. Two gaps that the revert sweep caught and this suite now closes: the Berserker Brand's checks must run **physics frames** while the relic is active (the old code wrote the field from `_physics_process`, so a synchronous getter read would have passed against the bug), and the group-name fix needs `Tà Khí` driven **end to end** rather than `spawn_specific_enemy()` called directly.
   - Full gate: **28/28 suites clean** via `./scripts/ci.sh`.

---

## Expansion 24.0: Hoang Tàn (The Two Leftovers)

The last of the same audit. A DoT rate that latched forever, and a meridian that described an effect nothing applied.

1. **Burn and Poison Rates Were Permanent High-Water Marks**:
   - `apply_burn()` did `burn_timer = max(burn_timer, duration)` and `burn_dps = max(burn_dps, dps)`. The `max()` is correct *while the effect is up* — a weaker burn landing on a stronger one should not downgrade it. But only the timer ever came back down. The rate was a per-enemy high-water mark **for the rest of the fight**: one 35.2 dps dragon breath permanently upgraded every later 28.8 dps fireball burn to 35.2. `apply_poison()` had the identical shape, and `_trigger_thermal_shockwave()` cleared `burn_timer` on cancelling a burn but left `burn_dps` behind.
   - Now each rate is handed back the frame its own effect ends. The `max()` on application is untouched — overlapping burns still take the strongest.

2. **Đan Điền's Advertised +20% AoE Now Exists**:
   - The meridian table has read "*+30% Dragon Soul & +20% AoE per level*" since the Codex shipped. The Dragon Soul half was wired (`dragon_soul_harvest_mult`). The AoE half was not: `refresh_meta_stats()` rebuilds the fireball's `blast_radius_multiplier` from `char_area_bonus` and the Pyro meta stat, and the meridian was simply not in the list.
   - Added as a term in that one line — the same place every other AoE source already had to be, because a source left out of a rebuild line is a source that silently does nothing.

3. **Automated Verification**:
   - `tests/test_expansion_24.gd` covers all four, each proven non-vacuous by reverting the fix and confirming the suite goes red. The Đan Điền checks read the sword multiplier out of the save rather than hardcoding it, because Ỷ Thiên Kiếm's `*= 1.25` tail scales the whole expression — the per-rank step is `0.20 × 1.25` on a machine with that sword equipped and `0.20` without.
   - The burn-rate checks assert the value the DoT tick actually reads (`max(1.0, burn_dps * 0.35)`) rather than a health delta: the test scene has a live player, live collision bodies and projectiles in flight, and an HP delta picks up hits that have nothing to do with the burn. A first attempt at exactly that comparison was removed after it proved racy.
   - Full gate: **29/29 suites clean** via `./scripts/ci.sh`.

---

## Expansion 25.0: Giờ Dừng (The Dash Paused the Clock)

The last item left on the audit, and the same bug class as 22–24: a one-frame-lifetime thing whose lifetime is owned by an unrelated branch. `_physics_process` splits into `if is_dashing: ... else: ...`, and two things that have nothing to do with dashing lived in the `else`.

1. **A Dash Stopped the Blizzard's Clock**:
   - `blizzard_slow_timer` decayed in the non-dash branch, right beside the speed maths that *consumes* it. Dashing therefore froze the debuff's own timer, so every dash handed Hàn Bão Sơn back its own duration as free time: 4.5s of slow that lasted 4.5s plus the whole dash in it.
   - Moved up into the top-of-frame timer block with its six siblings, which is where `glacial_slow_timer` already sat — the lease added in Expansion 23.0 has the identical shape, which is the tell that this is the same bug.
   - The 0.75× still applies to walk speed exactly as before. The dash itself was never slowed by the blizzard, and still isn't: `dash_velocity` is a fixed constant that no multiplier touches.

2. **A Dash Starved the Input Poll**:
   - `input_direction` is a one-frame latch — cleared, filled by the poll above it, read by the movement maths. The clear sat in the `else`, so once a dash started and the latch was holding a reading, the poll could not run again for the length of the dash. The stick froze at whatever it read when the dash began: `last_move_dir` — what the next dash falls back on and what every auto-aim reads when no key is held — stopped tracking for the whole 0.25–0.35s, and the frame after the dash ended the player drifted once in a direction they had already let go of.
   - The clear moved to the top of the frame, next to the poll that refills it. No new field, no new call path — the `if input_direction == Vector2.ZERO` guard became dead and went with it.

3. **Automated Verification**:
   - `tests/test_expansion_25.gd` covers both, each proven non-vacuous by reverting the fix. The input check had to get the ordering right: `SceneTree.physics_frame` is emitted *before* nodes process, so reading the latch after an await samples whatever the frame last wrote to it — a different moment in each build, and a check on the latch passes or fails on intra-frame ordering rather than on behaviour. It asserts on `last_move_dir` instead, which is persistent state.
   - It also has to flip the stick *after* the dash has run for a few frames. A latch cleared at the end of every non-dashing frame starts the dash empty, so flipping on the same frame the dash begins reads as a fix even with the poll genuinely dead — which is what the first two attempts reported. A real dash lasts 15+ frames.
   - The one-frame drift at the end of a dash is the same bug's other half and is deliberately *not* asserted: it plays out inside the movement maths, and the stale direction it drifts toward is the one the dash was already going, so nothing observable from outside a frame separates it.
   - The blizzard check sets the timer directly instead of calling `apply_blizzard_slow()`, which early-returns when the player has Van Hạc Hai equipped — and the saved game has exactly that, so going through the real path would have measured the immunity instead of the clock.
   - Full gate: **30/30 suites clean** via `./scripts/ci.sh`.

---

## Expansion 25.1: Sự Rơi Rác (Two Flakes In The Gate Itself)

Not new features. The second gate run of 25.0 came back **1 of 30** on a suite that had passed the first gate and passed in isolation — a flake, which is worse than a failure, because it means the gate cannot be trusted to say anything. Both were the same mistake, in two suites, and both were mine.

`enemy.take_damage()` opens with `var is_crit = randf() < crit_chance` where `crit_chance` starts at a flat **0.12**, and a crit multiplies the entire hit by 2.2. Any assertion that pins an exact damage number is therefore a coin-flip unless it pins the roll.

1. **Expansion 22.0, Huyết Ma Kiếm — 1 failure in 10 runs**:
   - `take_damage(100.0)` then assert the lifesteal healed exactly `100 × 0.04 = 4`. It set `crit_chance_bonus = 0.0`, which *leaves* the 12% base chance live rather than removing it. One hit in eight came out a 2.2× crit, the lifesteal correctly paid 4% of 220 = 8.8, and the assertion — which assumed a plain 100-damage hit — failed. **The product was right; the expectation was not.**
   - Now the crit is forced *on* the way the sibling test three functions up already does it (`crit_chance_bonus = 10.0`), and the expectation is computed from the hit that actually landed — `100 × 2.2 × get_crit_damage_multiplier()` — so it tracks the real contract ("4% of the damage dealt") instead of one sample of it. Reading `get_crit_damage_multiplier()` rather than assuming 1.0 keeps it correct on a save that has Đốc Mạch ranks in it. **Verified 0/20.**

2. **Expansion 9.0, Treasure Goblin — same coin-flip, same suite pattern**:
   - `take_damage(10.0)` then `assert(goblin.current_health == 65.0)`. A crit took it to 53.0 one run in eight. This one needed `seed(20260927)`: the goblin is instantiated with no player reference, so `crit_chance` is the bare default and there is no `crit_chance_bonus` lever to pull from the test. Seeding is the house answer — `test_wave_arena_milestone_2.gd` and `test_expansion_21.gd` already do exactly this for the same reason, and both carry the same comment. Nothing else in this suite reads the RNG, so shifting the stream costs nothing. **Verified 0/12.**

3. **The rest of the gate was audited, not assumed**:
   - Thirteen suites call `take_damage()`. Every other exact-damage assertion found is on the *player's* HP or on invulnerability, and every enemy-side one is a `<` threshold — a crit can only make damage larger, so those hold a fortiori. Those two were the only exact numbers exposed to the roll.
   - The reason the first two gates of 25.0 passed: at a 12% rate per exposed assertion, a clean run is roughly 88% likely, so two clean gates in a row is a ~77% coincidence, not evidence. A flake this size survives casual testing indefinitely.

---

## Expansion 26.0: Khí Thừa (The Shield That Refilled Itself)

Six audits came back clean first — the level-up catalog (34 offered IDs, 34 handled, exact 1:1), the intermission shop (all 6 scrolls' `apply` keys handled, every description matching its code), the relic table (6/6, and Chrono Hourglass's `max(1.25)` is a correct trick, not a bug — 1/1.25 = 0.8, exactly the advertised −20% cooldown), the weapon stat system (each weapon's cooldown is computed from its own field in the same file), the wave director (its two clocks are mutually exclusive, so no boss double-spawns), and the run-vs-meta stat split. Then the seventh found something.

1. **`refresh_meta_stats()` Tops the Qi Shield Back Up On Every Call**:
   - The line read `qi_shield_max = float(nham * 30)` then `qi_shield_current = qi_shield_max`. That is a *stat rebuild* silently healing the player.
   - It is called from a dozen places, and the two free ones are the ones a player hits by accident: `_close_shop()` in `hud.gd` and `equip_gear()` in `game_manager.gd` — the latter checks no gold at all. So: take a shield-breaking hit, open the menu, close it, and the shield is full again. As often as you like. (Physics is paused while the menu is open, so the shield cannot drain there; the toggle just hands you a fresh one each time.)
   - Now it grants only the capacity that was actually bought: `current = min(new_max, current + max(0, new_max - old_max))`. For a shield nothing has touched yet that is *the same number* — which is why this is not a behaviour change on a real save. The two only diverge once charge has been spent, which is the one case that must not refill.
   - `apply_shenron_wish("wish_immortality")` refills the shield on purpose and writes the field directly, so it is untouched and still works.

2. **Automated Verification**:
   - `tests/test_expansion_26.gd`, four groups, all four discriminating checks proven non-vacuous by reverting the fix. The revert output is the exploit in one line: from a broken 0/30 shield, one bought rank used to hand back a **full 60** — 30 points more than the player paid for.
   - Every assertion is synchronous and takes no physics frames on purpose. The shield regenerates by `0.75 × regen_rate` every frame, so one awaited frame between draining the shield and reading it back would refill it and hide the bug entirely.
   - One test's precondition was wrong on the first run, and instructively so: it assumed a refresh re-tops an already-capped shield. The fix makes that assumption false *on purpose* — an unchanged cap grants nothing — so the test now starts from the field's own zero, where "grant the delta" and "top up to the cap" are the same number.
   - Full gate: **31/31 suites clean** via `./scripts/ci.sh`.

---

## Expansion 27.0: Lưỡi Cùng Giờ (The Relic That Skipped The Blade)

The Đan Điền class again: an advertised effect that was never applied to one of the things it covers. The Chrono Hourglass reads "**−20% Weapon Cooldowns**", and the one place that applied it named the weapons by hand.

1. **The List Was Missing One Of The Five Weapons With A Cooldown**:
   - `apply_relic_effects()` listed `MainWeapon`, `LightningWeapon`, `FireballWeapon`, `AxeWeapon`. Those are four of the five nodes in the scene that read `speed_multiplier` into their cooldown — `slash_weapon.gd:82` does exactly what the other four do. **`SlashWeapon` (Độc Cô Cửu Kiếm, the tier-3 blade) was not in the list**, so a player who owned the relic *and* the blade got no cooldown reduction from either, and nothing in the UI hinted at it.
   - `OrbitingWeapon` is legitimately excluded: it orbits on a rotation and has no `speed_multiplier` and no cooldown at all.
   - Now swept across the `Weapons` container instead of named, using the same `for node in container.get_children(): if "speed_multiplier" in node` shape `wave_shop_ui._set_weapon_speed()` already uses. The guard skips the orbiting shield on its own, and **the next weapon added to the scene is covered without anyone remembering to list it** — which is the whole reason the original list had a hole in it.
   - The floor stays `maxf(current, 1.25)` rather than a multiply, so the relic remains safe to apply more than once and a weapon already faster than the floor keeps its own speed.

2. **Automated Verification**:
   - `tests/test_expansion_27.gd`, four groups, three discriminating checks proven non-vacuous by reverting to the four-node list. The revert output names the bug exactly: the blade reports `got 1` — sitting at its untouched default.
   - Every weapon's `speed_multiplier` is normalised to the field's own 1.0 before each check. The relic applies a *floor* of 1.25, which is only observable from below it, so without that a save that had already pushed a weapon past the floor would make the suite pass for the wrong reason.
   - The suite also pins down the two boundaries of the fix: `OrbitingWeapon` must *keep* having no cooldown (if it ever grows one, the guard needs to start covering it), and without the relic every weapon must be left alone.
   - Full gate: **32/32 suites clean** via `./scripts/ci.sh`.

---

## Expansion 28.0: Kim Thiềm (The Quest That Paid Out Nothing)

The silent-failure shape, and the worst one so far: a reward that was advertised, earned, claimed, and never granted.

1. **Two Hand-Typed Lists That Were Allowed To Disagree**:
   - Every quest's `reward_type` and every arm of `_apply_reward()`'s `match` are written by hand, and the `match` had **no default branch**. The quest **"Vạn Tiền Đại Phú"** (`rich_master`, bank 2,500 lifetime gold) declared `"reward_type": "gold_drop_buff"`. The handler spelled the same arm `"gold_drop_mult"`. Those were the only two spellings in the file, and `bonus_gold_drop_mult` is used consistently everywhere else — including the consumer in `add_gold()` — so the handler's spelling was always the intended one and the data was the typo.
   - The effect: a player accumulated 2,500 gold, claimed "**+30% Giá trị tiền vàng rơi**", and got **nothing** — with no error, because an unmatched `match` arm is a no-op, not a failure. The `push_error` above it could never fire.
   - Fixed in the data, one string. The other side of the fix is a `push_error` default branch naming the offending type *and* the quest id, so the next drift of this kind is reported instead of absorbed.

2. **The Save Was Never Damaged**:
   - `save_codex_data()` persists only `id`/`progress`/`unlocked`/`claimed`, and `load_codex_data()` re-matches each saved row **by id** back into the file's live `quests` array. `reward_type` is therefore read from source on every launch, so a data-side fix reaches saves that already exist — no migration, and no way to be holding a poisoned quest on disk.

3. **Automated Verification**:
   - `tests/test_expansion_28.gd` walks **every** quest against the handler's arm names — a foreign key between the two lists. Checking `rich_master` by id would have gone green the moment that one string was corrected and stayed green through the next typo.
   - The payout check asserts the *delta* and the *consequence* separately: a multiplier that moves but sits at or below `1.0` is the identical silent no-op in a new disguise, since `add_gold()` gates the whole bonus on `> 1.0`. That is why the neutral `1.0` default is pinned as a precondition.
   - The suite calls `_apply_reward()` directly and never `claim_reward()` — the latter is what persists and emits — so it needs no save backup at all, and leaves the developer's `save_data.cfg` untouched.
   - Reverting to the typo turns it red on 4 checks (`got 1`) *and* the new default arm prints `Codex reward type 'gold_drop_buff' has no handler (quest 'rich_master')`. 10/10 deterministic. Full gate: **33/33 suites clean** via `./scripts/ci.sh`.

---

## Expansion 29.0: Chiến Tích Lệnh (The Bounty Aimed At The Wrong Enemy)

A bounty advertised for one enemy, credited by a flag belonging to a *different* one.

1. **"Slay an Elite Champion" Was Credited To Ordinary Champions**:
   - `init_run_bounties()` offers four bounties keyed by a hand-typed `target_type`. One reads `desc: "Slay an Elite Champion"`, `target_type: "kill_champion"`, 80 gold for one kill.
   - The only thing that fed `kill_champion` was `add_kill()`'s second argument — named `is_champ`, fed `is_champion`. But **`is_champion` and `is_elite_champion` are siblings, not a nesting**: `make_champion()` sets `is_champion`; `make_elite_champion()` sets `is_elite_champion` and never touches the other. So the bounty was credited to ordinary affix champions and to *not one* real Elite Champion.
   - And a third caller made it worse: `goblin.gd` passed a hardcoded `true` for a **Treasure Goblin**, no kind of champion. A goblin therefore completed "Champion Slayer" (80 gold) *on top of* "Greed Hunter" (90 gold) — **170 gold of bounty from one kill**, earned from the enemy a player is least likely to read as a champion.

2. **The Fix Is Three Tokens, And The Flag Is Renamed To Match**:
   - `add_kill()`'s parameter is now `is_elite_champ`, `enemy.gd` passes `is_elite_champion`, and the goblin passes an explicit `false` (stated rather than defaulted, so the rejection reads as deliberate). The rename is not cosmetic: `is_champ` is precisely the near-miss that produced the inversion, and the whole bug lived at that boundary.
   - The bounty is still comfortably completable — elites spawn on a fixed schedule (90s, 180s, and twice in wave 5) against a target of one. It is now also worth what it pays: before, the easiest way to earn 80 gold for "slay an Elite Champion" was to kill an affix champion or a goblin, and roughly a hundred or more of those appear in a 20-wave run.
   - Judgement call worth flagging: the old behaviour may well have been the author's intent, with the description simply written loosely. The fix takes the **advertised text as the contract**, since that is what the player reads.

3. **Automated Verification**:
   - `tests/test_expansion_29.gd` drives the goblin end-to-end through the scene's own `die()`, so the argument in `goblin.gd` is genuinely under test rather than assumed. It also asserts the untouched branches still work — a bat must still feed Bat Hunter and must not feed Champion Slayer.
   - Every `target_type` in the bounty data must be one that something can actually feed, which is the same foreign-key check Expansion 28.0 added for Codex rewards, applied here.
   - The one check that reads source is labelled as such. `enemy.gd`'s call sits deep in `die()`, behind hitstop, particles and a `FloatingText` spawn; driving it would stall the suite on `Engine.time_scale` to test a single argument, and since the bug *was* a single hand-typed argument, nothing else would catch that token being reverted.
   - Targets are raised to 99 in the flag test so no bounty can complete, because completing one calls `add_gold()` → `save_game_data()`. The goblin test does write, so the save is backed up and restored byte-for-byte.
   - Both production reverts are caught independently (goblin: `champion bounty current 1 of 1`; enemy: 2 checks). 10/10 deterministic. Full gate: **34/34 suites clean** via `./scripts/ci.sh`.

---

## Expansion 30.0: Cầu Lửa Không Có Nhịp (The Weapon With No Fire-Rate Card)

Found by sweeping for functions with no call sites — which also turned up the one genuinely dead item in the codebase, `reset_rerolls()`.

1. **One Upgrade Method, Zero Callers**:
   - `fireball_weapon.gd` had `func upgrade_fire_rate(bonus) -> void: speed_multiplier += bonus`, and **no card in the shop could ever reach it**. It was the only `upgrade_*` method in the entire codebase with no caller.
   - The fireball's cooldown is `max(0.22, base_cooldown / (speed_multiplier * attack_speed))` — character for character the same formula as `slash_weapon.gd:82`, and the Cửu Kiếm *does* have a `+25%` card for exactly that field. So the Cầu Lửa was the **one weapon of six whose fire rate could never be improved**, while the code to do it sat unused since the weapon was written.

2. **The Other Five Were Checked First, So This Is Not A Balance Guess**:
   - Khiên Bát Quái and Cửu Thiên Lôi each offer two cards and expose exactly two methods — nothing missing on either.
   - Phi Đao writes its three fields directly (`weapon.damage_multiplier += 0.25`) instead of via methods, so it has no `upgrade_*` methods to be missing a card for.
   - Only the fireball had an upgrade method with no card. The fix is one catalog entry and one `match` arm calling the function that already existed, at `+25%` to match the Cửu Kiếm's identical mechanism.

3. **Automated Verification**:
   - `tests/test_expansion_30.gd` never names a card id at runtime. For each of the six weapons it observes *which of that weapon's own numeric properties its cards actually move* and requires that to be at least the number of `upgrade_*` methods the weapon exposes — read off `get_method_list()`, so a method added tomorrow is counted the day it lands. A new method with no card, or a card that moves nothing, both fail it.
   - The guard's failure output states the bug exactly: `reaches at least its 4 upgrade methods from 4 cards (moved: fireball_count, damage_multiplier, blast_radius_multiplier)` — three fields for four methods, while all five other weapons passed. That is the evidence the invariant is real rather than invented to fit.
   - Isolation is done by rank, not by hard-coded filtering: the focused weapon goes to rank 1 and the other five to rank 5 with `evolved` set, which excludes every unlock (needs rank 0), every evolution (rank ≥ 5) and every other weapon's cards (rank ≥ 5).
   - Reverting the card turns 9 checks red. 10/10 deterministic. Full gate: **35/35 suites clean** via `./scripts/ci.sh`.

---

## Expansion 31.0: Phần Thưởng Hằng Ngày Không Bao Giờ Được Trả (The Daily Reward That Was Never Paid)

Found by tracing every value a UI string renders, back to whoever is supposed to move it.

1. **The Panel Promises a Number, and Nothing Pays It**:
   - `leaderboard_ui.gd:211` renders `"💰 Phần Thưởng Hoàn Thành: +%d Vàng" % trial.get("reward_gold", 500)` straight off the dict `get_daily_trial_info()` returns. The four daily trials carry **600 / 750 / 800 / 900 gold**.
   - The status line directly below it reads `trial.get("completed", false)` and prints `✅ ĐÃ THAM GIA HÔM NAY`. The **only** assignment of that flag in the entire codebase was `submit_run()`'s. So the game detected completion, told the player it had happened — and never moved the gold. On any day, for any of the four trials.
   - This is not a misspelled `reward_type` or a key that two files spell differently. **There was no line that paid anything at all.** The sibling system sharing the key name pays correctly — `game_manager.gd:562` and `:778` both do `add_gold(b["reward_gold"])` for bounties — which is exactly what makes the omission easy to miss on a read.

2. **Meta Gold, Not Run Gold**:
   - Payout goes through a new `GameManager.add_meta_gold()`, deliberately **not** `add_gold()`. `add_gold()` multiplies by `golden_horseshoe`, doubles under Blood Moon and applies the Codex gold bonus, and it adds to `run_gold` too — which is the figure the end-of-run **Double Gold** rewarded ad doubles. Routing a flat daily reward through it would scale 600 by whatever relics the finished run happened to hold, then let the player watch an ad turn the same 600 into 1200.

3. **Once Per Day, And On the First Run of the Day**:
   - The guard hangs off the completion flag, not off the score comparison. The record is a high watermark, so beating it is the *normal* outcome of a second run — hang the payout off that and the daily 600 is farmable by dying repeatedly.
   - `get_daily_trial_info()` is called **before** the guard, because it is the only thing that rolls the date over and the rollover is what clears `daily_completed`. Call it afterwards and the first run of a new day scores, skips the payout, and then has its own completion flag cleared — a whole day's reward lost while the panel claims nobody played.

4. **Automated Verification**:
   - `tests/test_expansion_31.gd` drives the real `GameManager` and `LeaderboardManager`, so the payout path is exercised end to end. Six cases: the advertised number is the number paid; a worse run pays nothing; a **new daily best** still pays nothing; the first run of a new day pays; `run_gold` never moves; and Blood Moon does not double it — the last two being the assertions that distinguish this from a one-liner calling `add_gold()`.
   - Reverting the guard produces the bug's own signature: `Finishing the trial pays exactly the advertised 800, purse went 2631 -> 2631`, exit 1. Reordering *only* the `get_daily_trial_info()` call turns exactly one check red — the one written for it, and no other.
   - `tests/test_expansion_14.gd` also calls `submit_run()` twice, so it now snapshots and restores `total_gold` too. Both suites leave the save byte-identical; 5 consecutive runs of each move the purse by 0. 10/10 deterministic. Full gate: **36/36 suites clean** via `./scripts/ci.sh`.

---

## Expansion 32.0: Cầu Lửa Mất Rộng Mỗi Lần Mua Thêm (The Blast Radius The Shop Refunds)

1. **A Paid-For Upgrade That Deleted Itself**:
   - `Player.refresh_meta_stats()` **reassigns** `fire_wpn.blast_radius_multiplier` to rebuild the character / meridian / meta AoE sources, and it has twelve call sites — `buy_meta_upgrade()`, `equip_gear()` (free, repeatable), codex unlocks, character select.
   - The fireball's *own* run-scoped width was written straight onto that field: `upgrade_blast_radius()` did `blast_radius_multiplier += bonus`, and the evolution did `blast_radius_multiplier = 2.2`. So **Liệt Hỏa Phần Thiên** ("+35% Phạm Vi Nổ Cầu Lửa") took the radius 1.55 → 1.90, and the next rebuild put it back to 1.55. Buy the card, open the shop, and the card is refunded.
   - The same held for the Apocalypse Meteor's own widening — **the evolved Cầu Lửa reliably gained its 2.4× damage and silently lost its 2.2× width.**

2. **The Asymmetry Is What Makes It A Defect, Not A Choice**:
   - Nothing rebuilds the fireball's `damage_multiplier`, so the **+35% damage card survived every one of those call sites** while the +35% radius card did not. Same weapon, same shop, same moment — one axis stuck and one vanished.

3. **The Fix Is The Pattern Already In The File**:
   - `max_health` and might keep their run-scoped sources in `run_max_hp_bonus` / `run_might_bonus` for exactly this reason, and `refresh_meta_stats()`'s own comment names the hazard: *"anything applied to blast_radius_multiplier directly … would be wiped on the first refresh."*
   - The fireball gets the same treatment: a new `run_blast_radius_bonus` on the weapon, folded into the one expression. **Ỷ Thiên Kiếm's "+25% Bán kính tầm đánh"** — which was an `*=` on the rebuilt value, correct only because the assignment happened to run first — is now a `?:` term *inside* that expression, so the sword still scales whatever is in the blast and still comes all the way off.
   - Measured: bare base 1.24 → **1.9875** with a card, **3.4875** with card + evolution, **2.79** with the sword off. A fresh player with the sword and no cards is unchanged at **1.55**.

4. **Balance Note — This Restores Power That Was Advertised**:
   - The evolved fireball effectively ran at ~1.55× because the rebuild kept taking its width back. It now really holds ~3.05×. The card and the evolution were always in the shop text; they just were not in the game.

5. **Automated Verification**:
   - `tests/test_expansion_32.gd` pins the general rule first — a rebuild must be a **fixed point** over every derived field, so a source reintroduced outside the expression fails whichever way it comes back — then the specific promises: the card survives, the evolution survives, they stack in either order, the sword is exactly reversible, and radius and damage upgrades are now treated alike.
   - The suite **pins gear rather than inheriting it**. Ỷ Thiên Kiếm is multiplicative, so with it equipped a card is worth +0.4375, not +0.35 — every assertion would still be right about the game and wrong about the arithmetic. Verified passing with the sword forced both on and off in the shared save.
   - Reverting the fix gives the bug's own signature: `The +35% radius card survives a stat rebuild, went 1.24 -> 1.24 (expected 1.59)`, four checks red, exit 1. 20/20 deterministic. Full gate: **37/37 suites clean** via `./scripts/ci.sh`.

6. **Also Fixed In Passing — A 25% Coin-Flip In The Gate**:
   - `tests/test_expansion_23.gd` read the summoned enemy with `_newest_enemy()`, which took the **last entry of the `enemies` group array** — a positional guess, in a suite that deliberately leaves enemies standing between cases, and on a group Godot does not promise to return in insertion order. The offset assertion therefore failed whenever an older leftover sorted last: **2 failures in 8 runs.**
   - It now uses `_enemies_not_in()`, the identity-based helper already sitting in the same file. No assertion was weakened — the same two checks, against a provably-correct selection. 20/20 deterministic after the change.

---

## Expansion 33.0: Sấm Sét Không Bao Giờ Nhanh Hơn (The Last Weapon With No Speed Card)

1. **An Axis The Shop Could Not Sell**:
   - `lightning_weapon.gd:25` computes its cooldown as `base_cooldown / (speed_multiplier * _get_player_attack_speed())` — the same formula, character for character, as the Cầu Lửa at `fireball_weapon.gd:42`. The field is live, and the Chrono Hourglass relic sweeps it at `player.gd:824` like any other weapon.
   - But `LightningWeapon` exposed only `upgrade_strikes()` and `upgrade_damage()`, and `get_upgrade_catalog()` offered only `lightning_strike` and `lightning_damage`. **No card could ever raise it.** Four level-ups, two options each, and none of them touched the cooldown.
   - It is the slowest weapon in the tray to begin with — `base_cooldown = 2.4`, the longest of the six — so a lightning build was left holding the one axis it could never move. Every sibling sells it: Phi Đao `attack_speed` (+20%), Khiên xoay `orbit_speed` (+30%), Cầu Lửa `fireball_speed` (+25%), Rìu `axe_speed` (+25%), Cửu Kiếm `slash_speed` (+25%).

2. **The Fix Is The One The Sibling Cards Already Use**:
   - `lightning_speed` — **Lôi Trận Vân Tung**, "+25% Tốc Đánh Sấm Sét" — added to the offer list and to the `match` arm table, writing `speed_multiplier += 0.25` the way the dagger's `attack_speed` arm does at `upgrade_manager.gd:626` rather than through a new `upgrade_speed()` wrapper. Same `+25%` the three weapons sharing this exact formula charge.

3. **The Class Guard Was Blind, Not Absent**:
   - `test_expansion_30.gd` already owned this check — `_test_no_weapon_has_an_upgrade_method_no_card_can_reach()`, over all six weapons — and it passed, because it counts `upgrade_*` **methods**: lightning had 2 and 2 cards moved something, floor met. A weapon with no wrapper for a field it reads is invisible to a method count.
   - It now also asserts, per weapon, that some card moves the `speed_multiplier` its own cooldown reads. Read off the node rather than a hand-written list, so `OrbitingWeapon` (no cooldown, no such field) skips itself and a weapon added tomorrow is covered the day it lands.

4. **Balance Note**: Sấm Sét gains an axis it never had. Nothing else moves — the base cooldown, the strike count and the damage curve are untouched, and a lightning build that never takes the card plays exactly as before.

5. **Automated Verification**:
   - Reverting only the production fix turns two checks red with the bug's own shape: `LightningWeapon can raise the speed_multiplier its own cooldown reads (its cards moved: LightningWeapon.strike_count, LightningWeapon.damage_multiplier)` — the field named is the one nothing could reach.
   - 20/20 deterministic. Full gate: **37/37 suites clean** via `./scripts/ci.sh`, twice consecutively.

---

## Expansion 35.0: Boss Của Hiệp 20 Cũng Chỉ Mạnh Bằng Boss Hiệp 1 (Every Boss Was A Wave-1 Boss)

1. **The Curve Had Six Exits**:
   - `EnemySpawner._scale_for_wave()` is the only place the hiệp HP curve (`+floor(t*0.22)`) and the danger tier (`×hp`) are applied, and it must run *before* the node enters the tree because `enemy.gd:_ready()` seeds `current_health` from `max_health`. Its own comment claimed *"Every spawn path routes through here."*
   - Three of eleven did. `spawn_enemy_wave()`, `trigger_swarm()` and `spawn_specific_enemy()` called it. The other six did not: `spawn_intro_ambush()`, **`spawn_boss_1/2/3`**, **`spawn_demon_emperor()`**, `spawn_treasure_goblin()`.
   - So a boss's HP was whatever its scene was authored with, on every wave of the run. A hiệp-20 Dreadlord Malakor was 360 HP — **identical to the hiệp-1 one**, which is the whole defect in a single number.
   - `spawn_elite_champion()` was the near-miss: it called `_apply_danger()` (the tier) but not the curve, so a Tinh Anh Lệnh scaled with the difficulty setting and not with the hiệp.

2. **What It Cost, Measured**:
   | spawn | authored | before, hiệp 20 | after, hiệp 20 | after, hiệp 20 @ Hắc Ám |
   |---|---|---|---|---|
   | Dreadlord Malakor | 360 | **360** | 465 | 1395 |
   | Infernal Behemoth | 750 | **750** | 855 | 2565 |
   | Sòng Thủ Ma Tướng | 750 ×1.8 | **1350** | 1539 | 4617 |
   | Hắc Huyết Ma Hoàng (**the one wired to `trigger_victory()`**) | 2400 | **2400** | 2505 | **7515** |

3. **Balance Note — This Is A Large Difficulty Increase, Deliberately**:
   - The final boss at tier 5 goes from 2400 to 7515 HP: **3.1×**. The top of the run on Hắc Ám was a third of the fight the game had been computing for it, and every one of those enemies is now the fight it was always meant to be.
   - Nothing is inflated beyond the existing formula — the curve and the tier are the same two numbers `spawn_enemy_wave()` has always used. This is a correctness fix, not a rebalance, but it will read as a difficulty spike to anyone who finished a run on tier 5 in the last few versions.

4. **Two Things The Fix Had To Be Careful About**:
   - **`spawn_elite_champion()` replaced `_apply_danger()` rather than gaining a second call.** `_scale_for_wave()` calls `_apply_danger()` itself, so adding it alongside would have squared the tier — a tier-5 elite at 9× HP, worse than the bug being fixed. The suite pins the elite against *both* numbers.
   - **`spawn_boss_3()`'s 1.8× is applied after the scaling.** It reads `max_health` and writes `cur_hp * 1.8`, so the order decides whether Sòng Thủ is 1.8× a scaled Behemoth or a scaled 1.8× one — a bigger difference than the entire curve. Pinned explicitly, along with the claim that the Behemoth underneath it does carry the curve.
   - `spawn_hermit()` is deliberately left alone. The Lão Ngọan Đồng is the pact NPC; giving a non-combatant the combat HP curve would be a new bug.

5. **Automated Verification**:
   - `tests/test_expansion_35.gd` drives the real spawner at a pinned difficulty and tier, and restates the formula as a number read off each scene, so a balance edit to `boss.tscn` needs no second edit to the test. It expects `(authored + floor(t*0.22)) × tier × the spawn's own multiplier`, and every boss is found in the arena **by identity** — this suite leaves enemies standing between cases and the group is not insertion-ordered.
   - **Run against the unfixed code it produced 9 red**, with the bug's own numbers: `A hiệp-20 Dreadlord is tougher than a hiệp-1 one: 360 vs 360`, and `The final boss on hiệp 20 at tier 5 is 2400, the formula says 7515`.
   - The elite's expectation carries `Enemy.ELITE_HEALTH_MULT`, read off the class, because `_ready()` applies the 3.5× promotion *after* the wave scaling — getting that order backwards in the test was the one wrong assumption I had to correct.
   - 20/20 deterministic. Full gate: **38/38 suites clean** via `./scripts/ci.sh`, three consecutive runs.

6. **Also Killed This Turn — A Bug I Invented And Then Refuted**:
   - I read `coin.gd` / `gem.gd` reaching one unguarded `collect()` by two doors (`_process` at 18px and `_on_body_entered` at 22px) and concluded every coin paid out twice. A five-line probe settled it in one run: **after `queue_free()` a node's `_process` never runs again** — not later that frame, not ever. The engine skips nodes pending deletion, so the second door is already shut when the first one closes. No double-pay, no fix, and the suite went with it rather than shipping a test for a bug that does not exist.

---

## Expansion 36.0: "Score x11.0" (The Difficulty Tier's Score Multiplier Was Never Applied)

The character-select screen promises each difficulty tier a score multiplier. It is on screen, it is exact, and it has been on screen since the tier was added.

```
Tuyệt Thế  [5]  Tuyệt Thế
Enemy HP 300% · Speed 160% · Score x11.0
```

`character_select_ui.gd:160` builds that line from three of the six keys in `GameManager.DANGER`, and every one of the other two is applied — `hp` and `speed` both by `EnemySpawner._apply_danger()`. The third one, `score`, running x1.0 → x11.0, was read at character select to be *printed*, and then never read again anywhere in the codebase.

### 1. What was broken

```gdscript
# scripts/leaderboard_manager.gd
func calculate_score(run_time: float, kills: int, gold: int, scrolls_count: int) -> int:
    return int(run_time * 12.0) + (kills * 28) + (gold * 2) + (scrolls_count * 2500)

func submit_run(...) -> int:
    var total_score = calculate_score(run_time, kills, gold, scrolls.size())   # <-- no tier
```

`calculate_score()` is the raw formula, `submit_run()` is its only caller, and `submit_run()` is reached from both end-of-run paths — the game-over panel at `hud.gd:1040` and the victory panel at `hud.gd:1079`. Nothing between the difficulty screen and the leaderboard multiplied. A player who selected Tuyệt Thế for the eleven-times board and then survived all twenty hiệp banked **123100** — bit-for-bit what a Novice banks for the identical run.

| Tier | Enemy HP | Speed | Score (promised) | Score (banked) |
|---|---|---|---|---|
| 0 Novice | 100% | 100% | x1.0 | 123100 |
| 4 | 255% | 148% | x6.8 | 123100 |
| 5 Tuyệt Thế | 300% | 160% | **x11.0** | **123100** |

The ladder's own comment in `game_manager.gd` says the point is that the top tier "is worth surviving rather than merely avoiding" — the enemy half was worth it and the reward half was not.

### 2. The fix

Two lines in `submit_run()`, the single funnel where a run becomes a score:

```gdscript
var base_score := calculate_score(run_time, kills, gold, scrolls.size())
var tier_score := float(GameManager.get_danger_data().get("score", 1.0))
var total_score := int(roundf(float(base_score) * tier_score))
```

Three deliberate choices:

- **In `submit_run()`, not `calculate_score()`.** `calculate_score()` stays the raw formula, so a caller that has already scaled cannot be scaled twice, and every score already banked in the file under x1.0 stays the canonical number for the run that earned it. `test_expansion_14.gd:60` asserts exactly `8000` for `(100, 50, 200, 2)`; that assertion still means what it says, and still passes.
- **`roundf`, not a truncating cast.** `123100 * 4.2` is not exactly representable, and `int()` would floor it to 517019 — an off-by-one on every single run at that tier.
- **One place, so both boards move together.** `daily_high_score` is written from the same `total_score` a few lines below, so the daily trial's board gets the multiplier for free. Had the fix landed only on the tournament entry, a run would have scored 11× on one board and 1× on the other, and read as a worse run than it was.

### 3. Verification

`tests/test_expansion_36.gd` — five cases:

- **The ratio, not the absolute.** Two identical runs at opposite ends of the ladder. A run's score moves with every stat the player touches, so pinning an absolute value would make this a balance test that breaks every time a reward is rebalanced. Only the ratio is a promise the game makes.
- **The regression guard.** The raw formula still reads `123100`, and a tier-0 run is banked unscaled. If the multiplier ever reached into `calculate_score()`, this is the case that catches it.
- **Applied once, banked once.** The same shape as Expansion 35's elite: a tier-5 run scaled in two places would be 121×, which still sorts correctly and still looks like a big number, so nothing would *look* broken — the ratio is what catches it. Plus one entry per submission, checked by `is_player` count, since duplicate entries would inflate a rank count without changing any score.
- **The daily board carries it too.**
- **The promise on screen is the number applied.** The test builds the display string through the same `Loc.tf("danger.desc", ...)` call `character_select_ui.gd` uses, parses the multiplier back out of the rendered text, and compares it to the ratio actually produced. So a rebalance of the `DANGER` table, an edit to the desc string, or the three arguments arriving in a different order all fail here — instead of the two halves of the promise drifting apart in silence, which is the bug itself.

Reverted to the original file, the suite goes red with the bug's own signature:

```
The same run on tier 5 scores 1 times a tier-0 run: 123100 vs 123100 where the tier promises x11.0
The tier-5 run is the formula scaled once: 123100 where 1354100 is expected, not 14895100 (applied twice)
The daily high score kept the bigger of the two: 123100, not the tier-0 run's 123100
The tier promises "Enemy HP 300% · Speed 160% · Score x11.0" and delivers x1.00: the string and the score have drifted apart
```

...while the two regression guards stay green, so the suite is failing the bug and not everything. 20/20 deterministic. Full gate: **39/39 suites clean** via `./scripts/ci.sh`, three consecutive runs.

### 4. Two things I got wrong On The Way, Both Caught Before They Shipped

- **The suite hung rather than failed on first run.** `FileAccess.get_buffer()` takes a length in Godot 4.3. The parse error meant `_ready()` never ran, so nothing ever called `quit()` — exit 124, the signature of a hang rather than a failure. Worth remembering that a parse error in a suite and a failing assertion look identical from the gate's side and are not.
- **My `_submit()` helper read the score off the top of the board.** With the fix in, the tier-5 run (1,354,100) leads, and the tier-0 run submitted after it (123,100) sorts *below* it — so the helper returned the leftover leader and three cases failed on a test bug, not a product bug. Every run in this suite carries identical stats, so they cannot be told apart by value; the read is now a reference-identity diff against a snapshot of the board taken before the submit, the same technique `test_expansion_35.gd` uses for enemy groups.

### 5. Save Safety

`submit_run()` persists to `user://leaderboard_data.cfg`, and the daily-trial payout inside it pays meta gold out of `user://save_data.cfg` — so this suite writes two of the developer's files. Both are byte-backed-up at `_ready()` and restored at teardown, verified by md5 across a run: both `OK`, unchanged. The daily payout is skipped via `daily_completed` rather than by neutralising the reward, because the flag guards the payout and not the `daily_high_score` comparison that case 4 needs to make.

---

## Expansion 37.0: Thắp Nút Vàng Thêm Một Lần Nữa (The Rewarded-Ad Gold Doubling Was Claimable Forever)

The run ends. The game-over panel offers two things the player did not earn by playing well — a revive and a doubled purse — each behind a rewarded ad. One of them could be claimed as many times as you liked, and the repeats compounded.

### 1. What was broken

The revive is guarded. `has_revived_this_run` is set the moment the ad pays out and `hud.gd:1057` reads it straight back as the button's visibility, so a second click has nothing left to press.

The doubling had no such flag anywhere in the codebase:

```gdscript
# scripts/game_manager.gd
func double_run_gold() -> void:
    total_gold += run_gold
    run_gold  *= 2
```

And the button meant to stop a second press was undone one line later. In `_on_double_gold_pressed()`:

```gdscript
double_gold_button.disabled = true          # claim spent, button greyed out
double_gold_button.text = "Gold Doubled! (x2)"
_on_player_died()                           # refresh the stats label
```

...and `_on_player_died()` ends with:

```gdscript
double_gold_button.visible  = true
double_gold_button.disabled = false         # the guard, undone
```

So one ad view bought a button that stayed live. Worse, the payout reads the *already-doubled* `run_gold`, so repeats are not additive — they compound:

| Press | Payout | `run_gold` becomes |
|---|---|---|
| 1 | +R | 2R |
| 2 | +2R | 4R |
| 3 | +4R | 8R |
| 5 | **+31R** | 32R |

R(2ⁿ − 1) for n presses, for the price of the first ad view only.

### 2. The fix

The guard goes in the **function**, not the HUD:

```gdscript
func double_run_gold() -> void:
    if has_doubled_gold_this_run:
        return
    has_doubled_gold_this_run = true
    ...
```

This is the whole change to `game_manager.gd` plus one reset line in `start_new_run()`. Three lines of it are the argument:

- **In the function because the flag and the gold have to move together.** A function you can call twice must decide for itself — it cannot know whether a button was drawn correctly, and here the button demonstrably wasn't. This is the same shape as the codex reward guards: they look redundant at the call site and are not.
- **`hud.gd:1059` now derives instead of hardcoding.** `double_gold_button.disabled = GameManager.has_doubled_gold_this_run`, matching the revive line directly above it. One source of truth, and the `disabled = true` in the ad callback is deleted rather than kept — `_on_player_died()` re-derives it, so keeping both would have left the same bug in a different shape.
- **Reset in `start_new_run()`,** next to `has_revived_this_run`. Miss this line and the feature silently dies after the player's first run.

### 3. Verification

`tests/test_expansion_37.gd` — five cases:

- **The compounding, as arithmetic.** Five presses against `run_gold = 100`, exact equality both ways, so it is not a tolerance argument: `3100` and `3200` versus `100` and `200`.
- **The over-correction guard.** Every *other* assertion in the suite is satisfied by gutting `double_run_gold()` and returning early from the first call — the ad never pays, the button greys out, and cases 1, 3, 4 and 5 still pass. This case says the reward is still a reward.
- **A new run can claim it again** — the failure mode of the obvious alternative.
- **The flag is what the button reads,** plus the two rewards stay independent (a shared flag would be the lazy way to close this and would quietly remove the other button from the panel).
- Reverted to the original files, six red with the bug's signature, while the regression guards stay green. 20/20 deterministic. Full gate: **40/40 suites clean** via `./scripts/ci.sh`, three consecutive runs.

### 4. Two Notes On How The Suite Is Written

**The HUD is a node inside `main.tscn`, not its own scene.** There is no `hud.tscn` — I probed for one and instantiated `main.tscn` to see what it would cost, then didn't. Booting the whole game to read a `Button.disabled` back is not worth it, so the suite pins the flag the button is *derived from* and the money the function actually moves. That is sufficient rather than merely convenient: the claim is closed in `double_run_gold()`, so a live button can no longer pay a second time no matter how it is drawn. Case 4's comment says this in the file so the next reader does not mistake the coverage for an oversight.

**Every read of the new flag goes through `.get()`.** A direct `GameManager.has_doubled_gold_this_run` is a *parse* error until the flag exists, and a suite that cannot parse never reaches `quit()` — the gate sees a hang (exit 124) instead of a failure, and no red is ever recorded. Through `get()` this file compiles against both builds, so the pre-fix run is a genuine red. The suite also had to drop the `-> bool` return I first wrote on `double_run_gold()` for the same reason: the signature change is an API change to measure, and returning nothing turned out to be the smaller diff anyway.

### 5. An Orphan Found On The Way

`tests/test_gold_and_ui.gd` has no matching `.tscn`, so `ci.sh`'s `tests/*.tscn` glob never runs it — it is the only such file in the repo, and it happens to be the only *other* caller of `double_run_gold()`. Its assertions would still pass under the fix (`start_new_run()` clears the flag, so its single `double_run_gold()` still doubles 10 → 20). I have not deleted it: removing a test file is the caller's decision, not a drive-by.

---

## Expansion 37.1: The Gate Was Draining Your Save (And Faking A Flake)

Not gameplay — the harness. Found while chasing a one-off gate failure, and it explains that failure.

### 1. Ten suites write the developer's save, and one spends it

Every suite runs against the same `user://save_data.cfg` (Godot resolves `user://` to its own `app_userdata` directory on Linux and ignores `XDG_DATA_HOME`, so it cannot be redirected). Running all 40 suites once each and diffing the file:

| Suite | `total_gold` delta |
|---|---|
| `test_expansion_11` | **+2159** |
| `test_expansion_12` | **+4500** |
| `test_expansion_15` | +600 |
| `test_expansion_16` | **−2311** |
| `test_expansion_18` | +1060 |
| `test_expansion_19` | +30 |
| `test_expansion_8` | +210 |
| `test_expansion_9` | +270 |
| `test_scene` | +941 |
| `playtest_player_simulation` | +448 |

`test_expansion_16` is the only one that *spends*. The suite's own guard is "byte-backup and restore around any suite that buys meta gold" — which is per-suite bookkeeping that one suite forgot or a later edit undid. A gate loop drained the real save from 2831 to 2631 before this was found. (It is back at 2831; the value was restored by hand and the root cause is now fixed below, so it cannot recur.)

### 2. The second effect is worse: the gate is order-dependent

Because each suite inherits the previous one's writes, a suite can pass alone and fail after its neighbours run. That is **indistinguishable from a flake**, and it is how the sporadic gate failures in this repo's history should be read — not as nondeterminism.

I have to correct something I previously believed. One gate run in ten failed; the recorded cause was `enemy.take_damage()`'s unseeded `randf() < 0.12` crit roll multiplying a hit by 2.2. I measured it: **280 runs of all 14 damage-calling suites, 20× each — 0 failures**, then 16 more full gate runs, all green. The crit roll was not it. Suppressing crits in 14 files would have been a fix for a bug that was never occurring, so nothing was changed.

### 3. The fix — in the gate, not in ten suites

```bash
# scripts/ci.sh
SAVE_FILE="$(find ... -name save_data.cfg | head -1)"
SAVE_BACKUP="$(mktemp)"; cp "$SAVE_FILE" "$SAVE_BACKUP"
restore_save() { cp "$SAVE_BACKUP" "$SAVE_FILE"; }
trap '...; restore_save' EXIT

for suite in tests/*.tscn; do
    restore_save      # this suite starts from the developer's save, not its predecessor's
    ...
```

One snapshot, restored before every suite and on exit. Byte copy, never parsed — a re-serialised `ConfigFile` reorders keys, and a half-written save is worse than a missing one.

The ladder rung that applies: every one of the ten suites already had the knowledge of what it writes; none of them could be sure of *what the other nine had just written*. The gate is the one place that sees all of them.

### 4. Verified

- **40/40 clean** on a full run where the developer's save is now byte-identical afterwards (md5 `OK`, `total_gold` still 2831) — so no suite was quietly relying on the leakage.
- **6 consecutive gated runs**, all green, save untouched and `total_gold=2831` on every one.
- The per-suite byte-backup in `test_expansion_36.gd` and `test_expansion_37.gd` is left in place: it makes those two correct when run *by hand*, which bypasses the gate's isolation.

---

## Expansion 38.0: "VÀNG: 2931" (The Wave Shop Showed A Number It Would Not Spend)

There are two shops in this game, and they were written to two different rules.

### 1. What was broken

The hermit shop is consistent — it displays, checks and spends the same currency, three times over:

```gdscript
# hermit_shop_ui.gd
:72    gold_label.text = "Túi Tiền: %d" % GameManager.total_gold
:130   var can_afford = GameManager and GameManager.total_gold >= cost
:150   GameManager.total_gold -= cost
```

The wave shop checks and spends **run** gold:

```gdscript
# wave_shop_ui.gd
:89   func get_gold() -> int: return GameManager.run_gold
:93   GameManager.run_gold -= amount
```

...and its header displayed **the sum of the two**:

```gdscript
:399  _gold_label.text = "VÀNG: %d" % (GameManager.run_gold + GameManager.total_gold)
```

`run_gold + total_gold` is a value that is neither currency. It is not `total_gold` (the shop would never spend it) and it is not `run_gold` (the only thing it does spend), so it is not a number the player has, in the shop's terms, at all.

This is not a cosmetic mismatch, because every card's buy button is gated on `get_gold() >= price` at `:630`. A player carrying 100 run gold and 2831 banked saw:

```
VÀNG: 2931
```

above a shop where the 300-gold card is greyed out, the 800-gold card is greyed out, and pressing one anyway plays `ui_deny`. The header is the number the player reasons with when deciding what to buy; the game was counting a different one.

### 2. The fix — one expression

```gdscript
_gold_label.text = "VÀNG: %d" % get_gold()
```

Deliberately **not** the other direction. "Make the shop spend `total_gold`" also makes the header correct, and it is a serious balance change: `total_gold` is the purse that survives a run, so a player could bank gold, die, and spend the bank on run-scoped upgrades, making `run_gold` — the currency every wave payout and every in-run purchase is denominated in — decorative. A wave purchase is a run purchase, so the header reports the run purse, and the hermit shop's line is the model.

### 3. Verification

`tests/test_expansion_38.gd` — three cases:

- **The invariant:** the rendered number equals `get_gold()`. That single assertion subsumes the bug — if the header is the number the shop compares against, no price can be affordable on screen and refused in the shop.
- **Agreement, not a gap.** The second case asserts `purchase_card() succeeds == (header >= price)`. My first draft asserted "the header is above the purse" as a *precondition*, which only holds while the bug is present — so the suite passed on broken code and failed on the fix, exactly backwards. Stated as agreement it holds on correct code and fails on the defect.
- **The wrong fix, held shut:** a 50-gold purchase moves `run_gold` and leaves `total_gold` untouched, with the hermit shop pinned beside it as the worked example of consistency.

Reverted, both cases red with the bug's signature:

```
The header shows the purse the shop spends from: 2931 where get_gold() is 100
The shop's verdict matches its own header for a 300-gold card: header shows 2931, purchase refused
```

20/20 deterministic; the four existing shop suites still pass. Full gate: **41/41 suites clean** via `./scripts/ci.sh`, three consecutive runs, developer's save byte-identical after each.

### 4. A False Positive I Nearly Shipped

The pause menu renders `MIGHT: +%d%%`, `ARMOR: +%d`, `PYRO: +%d%%` from `get_meta_stat(...) * 10`, `* 1`, `* 12` — which look like arbitrary fudge factors standing in for the player's real values. They are not. `player.gd:444` applies `might * 0.10`, `:373` applies `pyro * 0.12`, `:724` reads `armor` directly — so the HUD's `* 10` and `* 12` are those same numbers expressed as percent, exactly. Measured before writing a word of the report, which is the only reason it did not become a third "advertised but not applied" entry defending a display that was right.

The one real gap there, left alone: the pause readout shows the **meta** contribution only, omitting `char_might_bonus` and `run_might_bonus`, so a player with character and scroll bonuses sees a lower number than they are actually playing with. That is a scope choice in a debug-style stat panel, not a broken promise, and "fix" it by showing the total would break its comparability across runs.

---

## Expansion 38.1: The One Suite That Spent Your Gold

Expansion 37.1 made `ci.sh` snapshot the save around the whole gate, which stopped ten suites inflating gold between each other. It did not stop the one suite that **spends** it.

`tests/test_expansion_16.gd:99` instantiates `hermit_shop_ui.tscn`, and section 5 buys its three elixirs. The hermit shop spends `GameManager.total_gold` — the purse that survives a run — so `test_expansion_16` is the only suite in `tests/` that can *destroy* progress rather than inflate it. Measured: **2311 gold per run, 2831 → 320.** I drained the save twice this way, once inside a 280-run loop and once by running the suite directly, and the second time was the more instructive: `ci.sh`'s isolation only protects gate runs, so a suite run by hand bypasses the harness entirely.

So the guard has to live in the suite, not only in the harness — a developer debugging one expansion runs that one scene, and that is exactly the path with no protection.

```gdscript
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e16bak"
```

`_backup_save()` at the top of `_ready()`, `_restore_save()` immediately before `get_tree().quit(0)` — the same byte copy and same sidecar `test_wave_arena_milestone_3.gd` already used, and byte copy rather than `ConfigFile` round-trip because re-serialising reorders keys.

### 1. Proof the guard is not vacuous

Deleting the `_restore_save()` call and running the scene directly:

```
total_gold=320
```

Restoring the call: `md5sum -c` → **OK**, byte-identical, and the sidecar removed. The gate is unchanged at **41/41 suites clean**, three consecutive runs, save byte-identical after each.

### 2. Why only this one

Nine other suites still *inflate* gold when run by hand. Inflating is harmless — you end up with more than you had — whereas spending destroys the run of state the whole ladder is built on. A guard that protects against the irreversible case and leaves the reversible one alone is the smaller correct diff; wrapping all ten would be ceremony.

---

## Expansion 39.0: "Xung Mạch bán 8%, bảng ghi 10%" (The Meridian Table Sold 40% For A 50% Promise)

`game_manager.gd:427` describes the Xung Mạch meridian as:

```
"desc": "+15 Move Speed & -10% Cooldown"
```

`player.gd:399` applied `xung * 0.08`. Eight percent against a row that says ten.

### 1. Why 8% is a defect and not a balance choice

Because the table's numbers are the contract, and seven of the other eight match their row exactly:

| Row | Advertised | Applied | |
|---|---|---|---|
| Nhâm Mạch | +30 Qi Shield, +1.5 HP/s | `nham * 30`, `nham * 1.5` | ✅ |
| Đốc Mạch | +7% Crit, +35% Crit DMG | `doc * 0.07`, `doc * 0.35` | ✅ |
| Xung Mạch | +15 Move Speed | `xung * 15.0` | ✅ |
| Xung Mạch | **-10% Cooldown** | **`xung * 0.08`** | ❌ |
| Đan Điền | +30% Dragon Soul, +20% AoE | `dan * 0.30`, `dan * 0.20` | ✅ |

The pause menu renders those `desc` strings verbatim (`hud.gd:1264`), so this is the string the player bought against: 1437 gold across five ranks for a 40% cut where the row promised 50%. The `maxf(2.5, ...)` floor is not the explanation either — the knight's 5.5s base is 2.75s at the advertised rate and 3.30s at the applied one, so the clamp binds on neither.

### 2. This was already the fourth bug in this table

Expansion 23.0 found Đốc Mạch advertising a **+35% Crit Damage** it never applied, in this same table. That fix patched the two numbers that were wrong. It did not add a rule, so the next mistyped decimal was free to land — and did, in a row one key away, six expansions later. The lesson is not "check the cooldown constant"; it is that a table of promises needs a test that reads the promises.

### 3. The test reads the row instead of restating the code

`tests/test_expansion_39.gd` is table-driven across all four meridians. `_advertised(id, half)` splits the `desc` on `&` and scans the first number out of the half it is given, so the expectation is parsed from the player-facing string rather than hardcoded:

```gdscript
var m_cd := absf(float(_advertised("xung_mach", 1)))   # 10
var expected_cd: float = maxf(2.5, _player.skill_cooldown_base * (1.0 - m_cd * 0.01 * 5.0))
```

The first draft of that case compared against `skill_cooldown_base * 0.6` — the code's number written out longhand — and passed, because restating a constant is exactly how the constant stays wrong. If the row is ever legitimately rebalanced, the test follows the row; if the code drifts from it, the test says so.

Buys go through `buy_meridian_upgrade()`, not a direct write to `meridian_upgrades`, so the cases measure the line a player in the pause menu actually runs.

### 4. A test suite was holding the bug in place

The gate went red three times after the fix, all of it `test_expansion_22.gd`:

```
FAIL: 5 ranks of Xung Mạch cut the timer by 40% once (expected 3.3, got 2.75)
```

Expansion 22.0's subject is compounding — that `refresh_meta_stats()` used to read `skill_cooldown_max * (1 - xung * 0.08)`, its own output, so ten unrelated purchases left a 2.4s timer. But its one hardcoded number, `base * 0.6`, was written from the line rather than from the row, and the message described it in the line's words: *"cut the timer by 40%"*. The code and its regression test were wrong together, which is why the assertion had to be updated to `base * 0.5` rather than the code changed back.

Its other two checks in that function compare against `bought`, read back from the player, so they were always rate-agnostic and are untouched.

### 5. Two reds in this suite were mine

The first run reported three failures. One was the real defect; the other two were a bug in the test: `crit_chance_bonus` stores its rate as a **fraction** (`doc * 0.07` → 0.35) while `get_crit_damage_multiplier()` stores it as a **ratio** (`1.0 + doc * 0.35` → 1.75). Both are right for their consumers — `enemy.take_damage()` compares the chance against `randf()` directly, and the damage one rides on the bare 2.2 crit constant — so the fix was a missing `* 0.01` in the test, not a change to either. Worth writing down because "unify the units" is the obvious next move and it would break one of them.

Verification: red first with the bug's own signature (`expected 2.75, got 3.3`), then 5/5 deterministic, then the fix reverted in place to confirm the suite still catches it, then `player.gd` restored byte-identical via `cmp -s`. Full gate **42/42 suites clean**.

---

## Expansion 40.0: "Hai thẻ nâng cấp tự xóa chính mình" (Two Cards That Undid Themselves)

Every level-up offers four **Universal Passive** cards unconditionally (`upgrade_manager.gd:383-388`). Two of them multiplied a player field in place:

```gdscript
"move_speed":  if player: player.move_speed *= 1.15     # :704
"magnet":      player.magnet_radius *= 1.30             # :707
```

Both of those fields are **reassigned from a base expression** on every `refresh_meta_stats()` (`player.gd:345-346`), so the multiply was discarded by the next rebuild. The file already names this exact pattern as a bug in two other places — `lightning_speed` at :357-366 ("was unreachable"), `fireball_speed` at :361-371, and `fireball_weapon.gd:21` ("Player.refresh_meta_stats() **reassigns** that"). Nothing had routed these two through a run-scoped source, so they were multiplying a value the next call replaced.

### 1. Nine call sites, three of them in the pause shop

```gdscript
hud.gd:1237                bought a meta upgrade
hud.gd:1278                bought a meridian
hud.gd:2236                settings / respec
game_manager.gd:490, :1026 codex + meridian purchases
codex_manager.gd:203       claimed a codex reward
character_select_ui.gd:330 re-equipped gear
```

So the repro is: pick **"+15% Tốc Độ Di Chuyển Thần Tốc"**, open the pause shop, buy one Vitality rank for 40 gold, and the card is gone. At 15% per copy and a card offered at *every* level-up, this is the most-picked card in the game silently doing nothing for most of a run.

The magnet card is worse. `refresh_meta_stats()` pushes `magnet_radius` into the `MagnetArea`'s `CircleShape2D` at `player.gd:351-353`, and that circle is what the player's magnet actually tests incoming gems against — so both the number *and* the thing that collects were rolled back together.

### 2. The fix was already in the file, once

`run_speed_mult` existed for the wave shop's Speed scroll (`wave_shop_ui.gd:178,182,192`). The card was the only writer that bypassed it. So:

```gdscript
# player.gd — the new field, beside the one that was already there
var run_magnet_mult: float = 1.0

# player.gd:346 — folded into the rebuild's own expression
magnet_radius = (140.0 + char_magnet_bonus + GameManager.get_meta_stat("magnetism") * 30.0) * run_magnet_mult

# player.gd:482 — mirrors multiply_run_speed()
func multiply_run_magnet(mult: float) -> void:
    run_magnet_mult *= mult
    refresh_meta_stats()
```

and the two arms collapse to one call each, which is what makes the fix *stick* — a card can no longer reach a rebuilt field:

```gdscript
"move_speed":  if player: player.multiply_run_speed(1.15)
"magnet":      if player: player.multiply_run_magnet(1.30)
```

The magnet arm's four lines of shape-following came out with them: `refresh_meta_stats()` already writes the shape, so a second writer was one more place to forget.

Checked that the enemy at `enemy.gd:161` (`move_speed *= 1.45` on the Swift affix) is *not* a sibling — that field is written once and never rebuilt, so it has the same shape and none of the bug.

### 3. A flat bonus and a multiplier are different units

The first green attempt came back with the speed card red: `expected 325.45, got 320.95`. Not a bad fix — a bad formula. `refresh_meta_stats()` adds two **flat** bonuses *after* the rebuild line: `move_speed += xung * 15.0` (`:402`) and `move_speed += 30.0` for Vạn Hạc Hai, the Speed Boots (`:421`). So the honest arithmetic is `230 * 1.1 * 1 + 30 = 283` and `230 * 1.1 * 1.15 + 30 = 320.95` — the multiplier applies to the character part and the flats ride along unscaled.

So the suite clears `equipment_slots` before measuring, the same lesson Expansion 37.1 taught about `storm_amulet`: a fixture that measures a stat should pin the stat's other contributors rather than inherit them from whoever's save is on disk. The card's promise is parsed out of the catalog's own `desc` string ("+15% Tốc Độ…") rather than restated as `1.15`, so a rebalance of the card follows the card — the discipline from 39.0.

### 4. Verification

Red first, with the bug's own signature, on both cards:

```
FAIL: ...and survives the stat rebuild (expected 290.95, got 253)
FAIL: ...and survives buying a meridian from the pause shop (expected 290.95, got 253)
FAIL: ...and the stack survives a rebuild too (expected 290.95, got 253)
FAIL: ...and survives the stat rebuild (expected 182, got 140)
FAIL: ...and so does the collection shape itself (expected 182, got 140)
FAIL: ...and survives buying a meridian from the pause shop (expected 182, got 140)
```

20/20 deterministic, then the fix reverted in place to confirm the suite still catches it, then `upgrade_manager.gd` restored byte-identical via `cmp -s`. Full gate **43/43 suites clean** (42 + this one), with the save md5-verified unchanged after every run.

---

## Expansion 41.0: "Ngựa Vàng Cho Tầm Hút, Rồi Cửa Hàng Lấy Mất" (The Relic The Pause Shop Took Back)

Two functions wrote the `MagnetArea`'s `CircleShape2D` and they disagreed:

```gdscript
player.gd:352   refresh_meta_stats()    shape.radius = magnet_radius
player.gd:833   apply_relic_effects()   shape.radius = magnet_radius
                                              + char_magnet_bonus
                                              + relic_magnet_bonus
```

`refresh_meta_stats()` has **nine** callers, three of them in the pause shop the player opens between any two fights. `apply_relic_effects()` has **one**, and it runs only on the single frame the relic is first picked off the floor (`relic_pickup.gd:65` → `add_relic` → `game_manager.gd:690`). The rebuild always wins: collect the Golden Horseshoe mid-run, walk into any shop, and its advertised **+60 pickup radius** is gone for the rest of the run.

### 1. Two more faults in the same line

`char_magnet_bonus` was added on top of a `magnet_radius` that already contained it (`player.gd:346`) — mage carries 60 and beggar 25, so those two double-counted their own pickup bonus for as long as they held the relic.

And `magnet_radius` itself **never received the +60 at all**. That is the field the pause panel prints (`hud.gd:687`, `:961`), so the panel showed a pickup range 60 smaller than the circle the game was actually collecting with. The suite's own failure message is the whole bug in one line:

```
FAIL: ...and the two agree, because exactly one function writes the circle (field 140, circle 200)
```

### 2. The fix was the file's own idiom, used twice already

Might and max health had both already been moved into a builder that reads its sources where the stat is computed. The relic joins them, read from the relic list the way `_build_might_bonus()` reads the equipped gear:

```gdscript
func _base_magnet_radius() -> float:
	var radius := 140.0 + char_magnet_bonus + GameManager.get_meta_stat("magnetism") * 30.0
	if GameManager.has_relic("golden_horseshoe"):
		radius += 60.0
	return radius * run_magnet_mult
```

`apply_relic_effects()` loses its magnet block and now just calls `refresh_meta_stats()` — so picking a relic up off the floor still moves the stat on that frame, but there is nothing left to order wrong. `relic_magnet_bonus` had exactly one reader, so the field is deleted outright. After the fix `shape.radius` is assigned in **one place in the entire codebase**.

Relics are cleared at `start_new_run():668`, so the "you already owned it" case is not reachable — worth stating because it looked like a fourth bug in the same function until that line was found.

### 3. A pre-existing 10% flake in the gate, found by the gate

The first gate after the fix came back `43/44`, `FAIL test_expansion_23`. It passes standalone, and the failing value was suspiciously *constant*:

```
CHECK FAILED: ...at the offset the pact asked for, got (219.7252, 22.42459)
```

A constant value means the **expected** is what moves. Probing it showed the player pinned deterministically at `(98.21, -22.03)`, so the requested offset was `(221.21, 22.97)` — and the summon landed exactly there, `dist=0`, in 12 of 12 runs. The ~1.5px shortfall is the summoned skeleton **starting to chase on its first physics step**: one frame at its wave-scaled speed is wider than the check's 1.0px tolerance. Measured at 3/30, and reproduced at 1/30 against the pre-41 `player.gd`, so it was not this change.

The claim under test is where the pact *put* the enemy, not that the enemy then stands still — and `add_child()` puts the skeleton in the `enemies` group inside its own `_ready()`, so the placement is readable before any frame runs. The `await` moved to *after* the assertions instead of before them. **60/60 clean** afterwards.

Worth recording as a process point: `ci.sh` prints the first three error lines but deletes `$LOG_DIR` in its `EXIT` trap, so a gate-only failure has to be reproduced by looping the suite standalone. The gate log alone cannot tell you what failed.

### 4. Verification

Red first on all three defects — the field, the circle, the rebuild, the pause-shop purchase, and the double count — then 20/20 deterministic, then the fix reverted in place and the same six failures returned, then `player.gd` restored byte-identical via `cmp -s`. Full gate **44/44 suites clean** three consecutive times, save md5-verified after every run.

---

## Expansion 42.0: "Miễn Nhiễm Hiệu Ứng Làm Chậm" (The Boots Were Immune To One Slow Out Of Two)

Vân Hạc Hài's row in the gear table (`game_manager.gd:151`) reads:

```
+30 Tốc độ di chuyển & Miễn nhiễm hiệu ứng làm chậm
```

The **+30** landed in `refresh_meta_stats()` and had always been right. The immunity was a guard inside `apply_blizzard_slow()` and nowhere else — so it read as "immune to slow *effects*", and it was granted against exactly one of the two in the game.

### 1. The slow the boots could not see

The glacial champion's aura does not call `apply_blizzard_slow()`. It writes the lease field straight onto the player, every physics frame it is inside 170px:

```gdscript
enemy.gd:251   player.glacial_slow_timer = maxf(player.glacial_slow_timer, 0.2)
```

and `_process()` consumed that timer in the movement maths with no gate at all:

```gdscript
effective_speed = move_speed * speed_multiplier * (0.65 if glacial else 1.0) * (0.75 if blizzard else 1.0)
```

The suite's own failure message is the whole bug in one line:

```
CHECK FAILED: A glacial champion cannot slow an immune player (multiplier 0.65, lease 0.2)
```

`0.65` is `GLACIAL_SLOW` and the lease is `0.2` — the aura took its lease, and the lease cost the player speed, wearing the boots that promise the opposite. This is the one slow a player meets in every wave, so for the rest of the game the second half of that row was inert.

### 2. The gate moved to where both timers are consumed

Not added to the second producer. The two timers were already summed in one expression, so the immunity now lives in that sum:

```gdscript
func is_slow_immune() -> bool:
	return GameManager != null and GameManager.has_equipped("van_hac_hai")

func get_slow_multiplier() -> float:
	if is_slow_immune():
		return 1.0
	var mult := 1.0
	if glacial_slow_timer > 0.0:
		mult *= GLACIAL_SLOW
	if blizzard_slow_timer > 0.0:
		mult *= 0.75
	return mult
```

`enemy.gd:251` needed no change at all, and the next slow to be added is covered by writing no new code. `apply_blizzard_slow()` keeps its own guard — that one is the *only* thing standing between an immune player and a stale blizzard timer, so the belt stays on the braces that were already there.

Worth being precise about what immunity means here: the aura still takes its lease, and the lease still expires on its own once the champion is gone. Nothing about the boots is meant to disarm an elite; the claim is only that the lease no longer costs speed. Case 2 asserts that expiry explicitly so immunity cannot quietly become a second latch.

### 3. A half-run suite that looked green

`_ready()` called the four cases like this at first:

```gdscript
_test_the_glacial_aura_cannot_slow_an_immune_player()
_test_the_blizzard_immunity_still_holds()
```

**A function containing `await` is a coroutine.** Called bare, it suspends at its first `await` and returns to `_ready()`, which marched on and hit `get_tree().quit()` while the rest of those cases had not run. Two of the four cases were that shape, so the suite reported one failure instead of two and looked closer to green than the bug was. All four are awaited now.

The tell was a failure count that did not change when the await was added. Had the cases been awaited but *also* wrong, the count would have moved.

### 4. Verification

Reverted by removing only the gate from `get_slow_multiplier()` and leaving the blizzard guard in place — the exact pre-fix behaviour, with both helpers retained so the file still parses. That build is red 3/3 with **exactly two** failures, and case 3 (the blizzard) still passes: the suite separates the two paths instead of failing wholesale. Fixed build **20/20** deterministic, `player.gd` restored byte-identical via `cmp -s`.

Worth recording as a diagnostic: those two failure strings were first read as coming from the *fixed* build, which is impossible — `is_slow_immune()` passing and `get_slow_multiplier()` returning `0.65` are only contradictory if both run the same code. Running the revert produced the identical pair, which is what located the confusion. When a red looks self-contradictory, the revert is the fastest way to find out which build you were actually looking at.

---

## Expansion 43.0: "Tiến Hóa Xong, Vũ Khí Yếu Hơn" (Evolving Made Your Weapon Worse)

Two of the six weapon evolutions **assign** an absolute value onto a field the player has been buying level-up cards into, so the evolution silently removes those cards' effect:

```gdscript
orbiting_weapon.gd:91   orbit_speed = 5.2
slash_weapon.gd:309     slash_range = 140.0
```

Every weapon offers its card at ranks 1–4 and its evolution at rank 5, so **full investment always precedes evolution** — the ordering the game guarantees makes this unavoidable rather than a corner case.

| Site | Field | Base | Card | Full build | Evolve assigns | Lost |
|---|---|---|---|---|---|---|
| `orbiting_weapon.gd:91` | `orbit_speed` | 3.8 | `+1.2` (`upgrade_speed`) | **8.6** | `5.2` | 3.4 rad/s |
| `slash_weapon.gd:309` | `slash_range` | 110.0 | `×1.25` (`upgrade_range`) | **268.55** | `140.0` | 128.55 |

Both fields are read straight into live play: `orbiting_weapon.gd:28` `current_angle += orbit_speed * delta`, and `slash_weapon.gd:206` `var effective_range = slash_range * (1.35 if is_evolved else 1.0)`. The evolved shield spins *slower* than the un-evolved one, and the evolved cleave reaches barely half as far as the card-invested weapon it replaced.

### 1. This file already had the right answer, nine lines away

`slash_weapon.gd:325` — the **other** slash evolution, `evolve_to_frost_sovereign()` — already reads:

```gdscript
slash_range = max(slash_range, 150.0)
```

The same field is floored in one evolution and overwritten in the other. `weapon.gd:118,120` and `slash_weapon.gd:319,320` use `max` too, so five sibling evolutions across the codebase already treat the evolution as a **floor** and these two were the outliers **among the fields a card scales**. The fix is one token each, in the idiom already established:

```gdscript
orbit_speed = max(orbit_speed, 5.2)
slash_range = max(slash_range, 140.0)
```

### 2. A third symptom, from the same line

The suite found a fault I had not predicted. The two slash evolutions are both reachable in one run (Lv.5 slash *and* Lv.5 shield), so the order is the player's to pick — and they disagreed:

```
CHECK FAILED: ...and on range (150 vs 140)
```

Frost-first left 150; nine-swords-first left 140. Two weapons that are otherwise byte-identical, differing by 10 units of reach, decided by the order the player happened to click. That is the same root cause: the second evolution's bare `=` clobbered the first one's `max`. One line, three failures.

### 3. The near-misses I checked and did *not* change

`fireball_weapon.gd:118` and `axe_weapon.gd:87` both read `damage_multiplier = 2.4`, which looks like the same bug. It is not: `damage_multiplier` starts at `1.0` and four `upgrade_damage(0.35)` cards land on **exactly** 2.4, so the assignment is a no-op at full investment and a gain below it. Correct as written.

`slash_weapon.gd:307` `base_damage = 75.0` against `:319`'s `max` looks like the same fault too, but `slash_weapon.gd:210` reads `slash_damage` in preference to `base_damage` whenever it is non-zero, which makes the damage number order-independent. The `:321` comment ("keep the legacy fields coherent") is doing exactly that job.

Worth stating, because both would have been defensible-looking changes that moved working code.

### 4. What the suite does *not* assert

It asserts the **invariant** — evolving must never lower a field the player bought cards into — and not a single number from the game. Every value is read off the live node, and every card is bought by asking the real catalog whether it is still offering the id and, if so, calling the real `select_upgrade()`. The ranks a weapon can spend on an axis are therefore *derived*, not restated.

That immediately paid. Predicting the shield's full build from the script default gives `3.5 + 4 × 1.2 = 8.3`; the suite measured **8.6**, because `orbiting_weapon.tscn:10` overrides `orbit_speed` to `3.8`. A suite built on a restated constant would have been wrong on the first run — and would have gone on passing for the wrong reason on every run after. (The slash *was* predictable: `slash_weapon.tscn` does not override `slash_range`, so `110 × 1.25⁴ = 268.5546875` exactly.)

Case 4 is the control that keeps the fix honest: a weapon nobody invested in must still *gain* from evolving, or `max()` would have turned every evolution into a no-op.

### 5. Verification

Red first on the unfixed code — all three failures, with the bug's own signature. Then reverted in place and the same three returned 3/3 with identical values, then both files restored byte-identical via `cmp -s`. Fixed build **20/20** deterministic. Full gate clean three consecutive times, save md5-verified after every run.

---

## Expansion 44.0: "Tiến Hóa Xong, Đạn Biến Mất" (Evolving Deleted Your Projectiles)

Expansion 43.0 swept the weapon fields a card **scales** and found two that a bare `=` clobbered. It did not sweep the fields a card **counts**, and all four of those have the same fault:

| Site | Field | Base | Card | Full build | Evolution assigns | Lost |
|---|---|---|---|---|---|---|
| `axe_weapon.gd:85` | `axe_count` | 1 | `+1` (`upgrade_count`) | **5** | `3` | 2 axes |
| `fireball_weapon.gd:116` | `fireball_count` | 1 | `+1` (`upgrade_count`) | **5** | `3` | 2 fireballs |
| `lightning_weapon.gd:136` | `strike_count` | 1 | `+1` (`upgrade_strikes`) | **5** | `4` | 1 strike |
| `orbiting_weapon.gd:90` | `shield_count` | 2 | `+1` (`add_shield`) | **6** | `5` | 1 shield |

All four upgraders use `+= 1`, and all four cards are offered at ranks 1–4 with the evolution at rank 5, so full investment always precedes evolution.

This is the most visible loss in the game. 43.0's `orbit_speed` and `slash_range` are numbers on a stat block; these are **objects on screen** — a player who bought "+1 Rìu/Bổng ném ra" four times watches the axes thin out at the exact moment a banner announces the evolution and the screen shakes.

The shield is the sharpest case, because it starts from 2 rather than 1. Its four cards reach 6, so the evolution's *own advertised* count of 5 is a **full card below** what the player already had. The evolution that is supposed to be the biggest payoff in a run made the weapon smaller.

### The fix

`maxi()` — the int-typed `max()` this codebase already uses at `upgrade_manager.gd:161` and `:223`:

```gdscript
axe_count      = maxi(axe_count, 3)
fireball_count = maxi(fireball_count, 3)
strike_count   = maxi(strike_count, 4)
shield_count   = maxi(shield_count, 5)
```

`orbiting_weapon.gd` needed nothing else: `rebuild_shields()` already runs last in `evolve_to_solar_bulwark()`, after the count is set, so a floored count of 6 correctly builds six blades.

### The lesson from having missed it in 43.0

43.0's §1 claimed these were "the outliers", and that was wrong — there were six, not two. The sweep had a shape: I listed every field a card writes to, and every field a card writes to on a *scaled* basis. Counts are the same bug wearing a different type, and the grep that found 43.0's two sites (`x *= literal`) could never have found them, because every one of these four is a `+= 1` in its upgrader and a bare `=` in its evolution.

The check that actually settled it was not a grep at all — it was reading each `upgrade_*` method next to its own `@export` base and asking what a full build would be. That reasoning, applied once, generalised to all four; applied to the 16 weapon fields in 43.0, it found two. The number of grep patterns I wrote mattered far less than whether the reading was done at all.

### Verification

Red first on the unfixed code — 4 failures with the bug's own signature, and the numbers matched the predicted full builds exactly (5, 5, 5, 6). Reverted in place, the same 4 returned 3/3 with identical values, then all four files restored byte-identical via `cmp -s`. Fixed build **20/20** deterministic, and Expansion 43.0's suite re-verified **20/20** on the shared `orbiting_weapon.gd`. Full gate clean three consecutive times, save md5-verified after every run.

---

## Expansion 45.0: "MIGHT: +0%" (The Panel Under-Reported The Damage You Were Dealing)

Every expansion in this game has turned on the same arithmetic existing in two places. Expansion 38.0 was a HUD that showed gold it would not spend; 39.0 was a shop table selling 40% against a 50% promise; 40.0 was two cards that undid themselves; 43.0 and 44.0 were evolutions that clobbered the field a card had bought into. This one is the simplest and the worst, because the game **already fixed the arithmetic and never told the panel**.

### The four sources, and the one that was shown

The damage the player actually deals is built in `player.gd:456`:

```gdscript
func _build_might_bonus() -> float:
    var bonus := GameManager.get_meta_stat("might") * 0.10 + char_might_bonus + run_might_bonus
    if GameManager.has_equipped("y_thien_kiem"):
        bonus += 0.15
    return bonus
```

That lands in `meta_might_bonus` (`player.gd:346` on every `refresh_meta_stats()`, and `player.gd:492` inside `add_run_might()`), which is the additive term of `get_might_multiplier()` at `player.gd:901`. Four sources feed it. Both places the player *reads* it reported one:

| | Source | Contributes |
|---|---|---|
| ✅ shown | `get_meta_stat("might") * 0.10` | meta upgrade |
| ❌ hidden | `char_might_bonus` | the character's innate bonus (`player.gd:216`) |
| ❌ hidden | `run_might_bonus` | relic / card / Shenron bonuses bought *during the run* |
| ❌ hidden | `has_equipped("y_thien_kiem")` | +15% for the equipped sword |

Both call sites were byte-identical:

```gdscript
var might = GameManager.get_meta_stat("might") * 10   # hud.gd:688, :962
```

`hud.gd:688` feeds the pause panel's `MIGHT: +N%`. `hud.gd:962` feeds `passives_label`, the `ATK +N%` bar. **The passives bar is the worse of the two** — it is drawn every frame of every run, and unlike the pause panel there is nowhere else to look and notice.

Measured on the shared save (meta might 2 → 20%), the panel showed a flat `20` no matter what else the player had:

| Case | Shown | Actual |
|---|---|---|
| `char_might_bonus = 0.20` | **20** | 40 |
| `+ add_run_might(0.25)` | **20** | 45 |
| `+ Ỷ Thiên Kiếm equipped` | **20** | 60 |

A knight with a 20% character bonus and the equipped Kiếm was told he had 20% might while dealing 60%. Nothing about the run felt broken — the hits were the right size. The panel was the only thing lying.

### The fix

Ask the node, instead of recomputing a term of its sum:

```gdscript
var might = int(roundf(player.meta_might_bonus * 100.0)) if player else int(GameManager.get_meta_stat("might") * 10)
```

The `if player else` arm is not a fallback — it preserves the old behaviour for the frames before a player exists (title screen, main scene before spawn), matching the `int(player.move_speed) if player else 230` idiom two lines above it in both functions.

This form cannot drift again, and that is the whole point. Had I instead written the four-term sum at `hud.gd:688`, the display would have been correct and would have started rotting the next time a fifth source was added to `_build_might_bonus()`. **One copy of the arithmetic, not two.**

### The lesson, which is the ninth instance of one

The comment above `_build_might_bonus()` already records a version of this exact bug being fixed on the *computation* side: "Ỷ Thiên Kiếm's +15% used to be added inline at the tail of `refresh_meta_stats()`, which meant `add_run_might()` ... quietly deleted an equipped weapon the first time a player bought Cửu Âm Chân Kinh. Every source is in the expression now." The author was right, fixed it, and left both readers holding the old one-term copy.

That is the real hazard in this codebase, and it is not carelessness — every one of these bugs is a *correct-looking* line that was correct when written. **Fixing one copy of an expression guarantees the others are stale, and the stale one is usually the one a player can see.** The durable check is not "did I grep for this constant" but "does any other site restate the same arithmetic" — and the durable fix is to delete the second copy rather than repair it. `get_might_multiplier()` is the reason this bug is survivable at all: the combat half has one copy, so the display could be made to read it instead of guess at it.

### Verification

Red first on the unfixed code — 6 failures, all reading `shown 20`, against actual values of 40/45/60. Reverted the logic in place (keeping the new comments, so the file still parsed) and the same 6 returned. Restored byte-identical via `cmp -s`. Fixed build **20/20** deterministic. A control case that passes both before and after — every non-meta source at zero — proves the parse and the label format are sound, so the six fail for the right reason rather than a broken harness. Full gate clean three consecutive times, save md5-verified.

---

## Expansion 46.0: "ARMOR: +2" (The Panel Under-Reported The Damage Reduction Too)

Expansion 45.0 ended with a line that reads like a method: *"the durable check is not 'did I grep for this constant' but 'does any other site restate the same arithmetic'."* The two stats printed **two lines below** the MIGHT readout on the same panel were the same arithmetic.

### One term of four, again

The armour the game actually subtracts is built in `player.gd:757`:

```gdscript
var meta_arm  = GameManager.get_meta_stat("armor") if GameManager else 0
var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
var total_armor = meta_arm + char_armor_bonus + equip_arm + shop_armor_bonus
```

Both display sites derived their number from `meta_arm` alone:

| | Source | Contributes | Shown? |
|---|---|---|---|
| ✅ | `get_meta_stat("armor")` | 1 flat per meta level (`game_manager.gd:384`, "-1 Damage Taken per level") | yes |
| ❌ | `char_armor_bonus` | the character's innate armour (`player.gd:212`) | no |
| ❌ | `equip_arm` | Nhuyễn Vị Giáp's flat 2 | no |
| ❌ | `shop_armor_bonus` | every point bought in the wave shop (`player.gd:136`) | no |

Measured on the shared save (meta armour 2), with +3 character and +4 shop armour:

| Case | Shown | Actually applied |
|---|---|---|
| char 3 + shop 4 | **2** | 9 |
| same, passives bar `DEF` | **2** | 9 |
| `+ Nhuyễn Vị Giáp` | **2** | 11 |
| giáp unequipped again | **2** | 9 |

Unlike the MIGHT bug, this one errs in the player's favour: they under-estimate their own survivability. That is why it survived in a codebase where the 45.0 twin was found in minutes. `shop_armor_bonus` is the one that matters — it is a **run-scoped** number, bought during the run, precisely the kind of value a player opens the pause panel to watch go up.

### The fix: delete the second copy, don't repair it

`total_armor` was a local inside `take_damage()`, so there was nothing to read off the node. The fix is to *make* the one copy addressable rather than to write the four-term sum a third time in the HUD:

```gdscript
func get_armor_bonus() -> int:
	var meta_arm = GameManager.get_meta_stat("armor") if GameManager else 0
	var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
	return meta_arm + char_armor_bonus + equip_arm + shop_armor_bonus
```

`take_damage()` calls it (`:757`), and both display sites call it (`:694`, `:973`). The sum now exists **once**. Writing it inline in the HUD instead would have produced a green suite and a third copy — the 45.0 lesson applied to its own successor.

`PYRO` was audited in the same sweep and left alone. `game_manager.gd:383` documents the stat as "+12% AoE Radius per level", and `get_meta_stat("pyro") * 0.12` at `player.gd:379` is indeed the AoE term, so the number is right and only the label is misleading. A wrong *label* on a correct *number* is a different bug class from a wrong number, and it is not one this expansion earned the right to fix.

### The claim under test is behavioural

45.0 compared a label against a field. This one does not restate the formula at all — it **measures** the armour by dealing a known 60 damage and differencing the health, then asserts the label reports that. So the suite cannot pass by agreeing with a stale copy of the expression, and it would also catch a *future* fifth source, whether or not that source is in the panel.

Getting there required neutralising everything else on `take_damage()`'s damage line — the dodge roll (an unseeded `randf()`), the qi shield, `char_damage_taken_mult`, the Blood Covenant's 1.20, and the phoenix-feather rebirth. One of those was missed on the first run and **the control case caught it**: `take_damage()` sets i-frames on every hit and its first line guards on `is_invulnerable`, so every probe after the first dealt nothing and read as "armour absorbed the whole 60". A control that passes both before and after a fix is normally there to prove the *harness* is sound; here it earned its place by failing.

### Verification

Red first — 5 failures, all reading `shown 2` against actual values of 9/9/11/9/9, with the control passing. Reverted the two HUD lines in place (keeping the accessor so the file still parsed) and the same 5 returned. Both files restored byte-identical via `cmp -s`. Fixed build **20/20** deterministic, and Expansion 45.0's suite re-verified green on the `hud.gd` this one also edits. Full gate clean three consecutive times, save md5-verified.

---

## Expansion 47.0: "Đổi Tướng Hai Lần, Tốc Đánh Nhân Đôi" (Re-Selecting A Hero Stacked Its Bonus)

Expansion 45.0 fixed a HUD that restated one term of a four-term sum. 46.0 fixed the line below it. This one is the same shape wearing a different hat: **a value that is added, never taken back.**

### Two bonuses, one block, two different forms

`player.gd:238`, in `apply_character_data()`:

```gdscript
var main_wpn = get_node_or_null("Weapons/MainWeapon")
if main_wpn:
    main_wpn.set("pierce_bonus", pierce_bonus)
    if data.has("attack_speed_bonus"):
        main_wpn.speed_multiplier += data["attack_speed_bonus"]
```

`pierce_bonus` is set absolutely, so it is idempotent by construction. `attack_speed_bonus` is added with `+=`, and **nothing records what it last added** — because there is nowhere to record it. `weapon.gd:17` initialises `speed_multiplier` to `1.0` and every other writer only accumulates into it: `upgrade_fire_rate` does `+=`, the wave shop's `_set_weapon_speed` does `*=`. The field has no owner that ever rebuilds it, so an addition is permanent.

That block was written assuming one call per player, from `_ready()`. It stopped being the only caller when the pause menu grew a hero button:

```gdscript
hud.gd:245   pause_hero_button.pressed.connect(func(): open_character_select("pause"))
```

`character_select_ui.gd:325` finds that live player with `get_first_node_in_group("player")` and re-applies the character to it — mid-run, on the weapon the player has been upgrading all along.

Ranger's card advertises `+35% Tốc Đánh`. Pause, switch to Ignis, switch back, and the dagger is firing at +70%. Again, +105%. The only button `character_select_ui.gd:309` disables is the *active* hero's, so leaving and coming back is precisely the path left open.

Measured, from the suite:

| | Fire rate | Advertised |
|---|---|---|
| fresh ranger | 1.35 | 1.35 ✅ |
| re-apply ranger | **2.05** | 1.35 |
| switch to Ignis | **2.05** | 1.00 |
| Ignis → ranger | **2.40** | 1.35 |
| …with a Tốc Đánh card bought first | **3.25** | 1.85 |

The Ignis row is a second bug in the same three lines: the `if data.has("attack_speed_bonus")` guard means a hero *without* the bonus never removes the *previous* hero's. Ignis was firing at Ranger's rate.

### The fix, and the wrong fix it had to avoid

The obvious repair — `main_wpn.speed_multiplier = 1.0 + data["attack_speed_bonus"]` — is idempotent, passes four of the five cases, and **refunds every Tốc Đánh card the player bought**, because the cards accumulate into this very field. That is Expansion 43.0's invariant (*evolving must never lower a field the player has bought into*) arriving from a completely different direction, and it is why the suite carries an explicit case that simulates a bought card before re-selecting.

So the fix takes back exactly what this line last added, and nothing more:

```gdscript
main_wpn.speed_multiplier -= applied_char_attack_speed
applied_char_attack_speed = float(data.get("attack_speed_bonus", 0.0))
main_wpn.speed_multiplier += applied_char_attack_speed
```

with a new `applied_char_attack_speed` field. The `if data.has()` guard is gone: `data.get(..., 0.0)` makes a hero with no bonus *remove* the previous hero's, which is what the player expects from picking a different character.

### The lesson: "added" and "owned" are different facts

A value that is only ever added has no way to know what it contributed, so it cannot be replaced. `pierce_bonus` sits one line above `attack_speed_bonus` in the same block and does not have this problem, because it is *owned* — assigned, not accumulated. The tell was never the `+=`; it was that the two lines disagreed about ownership and nothing in the file recorded the difference.

The generalisable check, and the third one this codebase has now needed: for every `x += v` on a field someone else also writes, ask **what happens the second time**. 43.0 and 44.0 asked "does a bare `=` clobber this?" and 47.0 asks the mirror — "does an additive write ratchet?" Both are the same question, which is whether the field has a single owner. It does not; it has an *initializer* and an *adder*, and only the first of those can be reasoned about.

### Verification

Red first — 6 failures carrying the bug's own signature (`2.05` where `1.35` was advertised, `2.05` as Ignis where `1.00` was advertised), with the fresh-ranger control passing. Reverted the block in place (keeping the new field so the file still parsed) and the same 6 returned. Restored byte-identical via `cmp -s`. Fixed build **20/20** deterministic, and Expansion 45.0's and 46.0's suites re-verified green on the `hud.gd` and `player.gd` this one edits. Full gate clean three consecutive times, save md5-verified.

Two harness bugs surfaced and were fixed before the red was trusted, both worth recording: the bootstrap called `apply_character_data()` after `add_child` — which already runs it from `_ready()` — so the *first* case read `1.7` on a fresh Ranger and the suite was demonstrating the very defect it claimed to test. And the last case asserted an absolute rate after a previous case had deliberately left a bought card on the weapon; the invariant there is that the round trip is a *no-op*, not that it lands on the base. In both cases the fix was to the test, never to the expectation.

---

## Expansion 48.0: "Mua Xong Xong Rồi Mà Bánh Nổ Vẫn Như Cũ" (The AoE Card Did Nothing When You Bought It)

**Symptom.** The player levels up, takes *Liệt Hỏa Phần Thiên* ("+35% Phạm Vi Nổ Cầu Lửa"), and keeps firing the same size of explosion. The width shows up eventually — twenty seconds later, when a relic pickup happens to rebuild something unrelated — but not when it was bought. Same for the evolution: a player who invested in the card at ranks 1-4 evolves into Apocalypse Meteor and the meteor lands at the un-evolved size.

**Cause.** Two sources, one rebuild, and the rebuild was never called:

| Site | Role |
|------|------|
| `scripts/player.gd:391` | the only place `blast_radius_multiplier` is assigned — from `run_blast_radius_bonus` plus the character, pyro and Đốc Mạch terms |
| `scripts/fireball_weapon.gd:108` | `upgrade_blast_radius()` — the card, `run_blast_radius_bonus += bonus` |
| `scripts/fireball_weapon.gd:130` | `evolve_to_apocalypse_meteor()` — the evolution, `run_blast_radius_bonus += 1.2` |
| `scripts/upgrade_manager.gd:686` | hands the card to `upgrade_blast_radius()` and returns |

Nothing on the level-up path reaches the rebuild: `select_upgrade()` returns after the call, and the button that bought the card (`upgrade_manager.gd:526`) connects straight to it. So the bonus was banked and invisible, and the field the projectile actually reads — `fb.blast_radius *= blast_radius_multiplier` at `fireball_weapon.gd:74` — kept the number it had.

This is the mirror of Expansion 44.0, which moved this bonus *off* `blast_radius_multiplier` onto a run-scoped field precisely so a rebuild would fold it back in rather than erase it. The write was relocated and the rebuild that applies it was never triggered: the card became durable and inert.

The five player-side run-scoped fields make the shape obvious. Four of them write and rebuild in the same two-line function — `add_run_max_hp` → `_base_max_health()`, `add_run_might` → `_build_might_bonus()`, `multiply_run_speed` / `multiply_run_magnet` → `refresh_meta_stats()`, `add_run_crit` → `crit_chance_bonus = ...`. `run_blast_radius_bonus` is the lone one whose writers live in a different file, and neither reached it.

**Fix.** `run_blast_radius_bonus` got a setter, so rebuilding happens on the write rather than at the two call sites:

```gdscript
var run_blast_radius_bonus: float = 0.0:
	set(value):
		run_blast_radius_bonus = value
		var p := get_tree().get_first_node_in_group("player") if get_tree() else null
		if p and p.has_method("refresh_meta_stats"):
			p.refresh_meta_stats()
```

A setter rather than a helper call in both writers because that is the shape that stays true for the next writer, and `refresh_meta_stats()` reads the field rather than writes it, so there is no recursion — verified by the suite, not assumed.

**An existing test was asserting the bug.** `tests/test_expansion_30.gd` checked that the four fireball cards touch `distinct.size() == 4` fields. That passed *because* the radius card moved only the run-scoped field and never the one the game plays from. Its stated purpose — "so no two of them can turn out to be the same field renamed" — is a no-collision check, and a total is the wrong way to express one. Rewritten to buy each card against its own baseline and report any field two cards both move. Revert-proofed by injecting a real collision (`fireball_speed` writing `damage_multiplier`): it fails naming both the field and the two cards.

**Lesson.** Durability is not the same as effect. Expansion 44.0 asked *can this bonus survive a rebuild?* and got the right answer; nobody then asked *does the rebuild ever run?* A field that is only ever read inside someone else's rebuild needs that rebuild as part of its own write path — otherwise it is a value with no effect, which is indistinguishable from a missing feature.

**The gate then surfaced two more things, both in the harness rather than the game.**

*One stale copy of a formula, from Expansion 46.0.* `tests/test_expansion_11.gd` rebuilt the damage path by hand to predict how deep the Qi Shield drains, and its copy had fallen behind the accessor it predates: it omitted `shop_armor_bonus` (the fourth term `get_armor_bonus()` gained in 46.0) and dropped the `char_damage_taken_mult` factor entirely. The suite inherits its character from the shared save, and the save held `"selected_character": "pyro"` — Ignis carries `damage_taken_mult: 1.15`, so the shield was drained correctly 15% deeper than the expectation. Repaired the way 46.0 repaired `hud.gd`: ask the player instead of restating the arithmetic. The derived expectation is character-independent by construction, so it needs no pin — and `select_character()` persists to the shared save, so a pin here would have reached every suite running after it.

*One suite leaking into the rest of the gate.* Every suite shares one `user://save_data.cfg`, this one runs early alphabetically, and it both buys `nham_mach` and hands itself 5000 gold — with `buy_meridian_upgrade()` calling `save_game_data()` on the way out. The rank it bought survived into later runs, so a player spawned with a 30-point Qi Shield, and the three suites that deal exactly 30 damage to check that HP drops — 19, 20 and `hit_stop` — watched the shield absorb it and reported false failures. **The shield was right; the suites that could not see it were wrong.** Gave Expansion 11.0 the same `user://save_data.cfg.e11bak` sidecar every other persisting suite here uses. No game file changes.

Worth recording about how that surfaced: Expansion 19.0 and 20.0 print `ALL EXPANSION 19.0 TESTS PASSED 100% CLEANLY!` on the same run where their `assert()` fires. A failed `assert()` only logs a `SCRIPT ERROR` and keeps going, so the suite's own pass line and the gate's verdict disagree — `scripts/ci.sh` catches it only because it greps stderr. Both suites here use `assert()` throughout, which also means a real failure aborts the rest of `_ready()` and hangs until the 120s timeout instead of reporting.

**Verification.** Red first — 4 failures carrying the bug's signature (`got 1, expected 1 + 0.35`), with the durability control proving the field was already banked (`1 -> 2.05` on rebuild, exactly `1.0 + 3 × 0.35`). Reverted the setter in place and the same 4 returned. Restored byte-identical via `cmp -s`. Fixed build **20/20**; the rewritten Expansion 30.0 suite **20/20**, and every one of the 16 other suites that touch the fireball re-verified green on the `fireball_weapon.gd` this edits. Expansion 11.0 green on the Ignis save that had been failing it, with the sidecar confirmed by running it and finding `nham_mach` absent from the save afterwards. Full gate **51/51** clean three consecutive times.

---

## Expansion 49.0: "Tiêu Diệt Toàn Bộ Ma Vật Trên Bản Đồ" (The Wish Promised A Map Clear And Killed One Enemy)

**Triệu hồi bão Thần Kiếm thiên hà trong 20s tiêu diệt toàn bộ ma vật trên bản đồ!**
— "Summon a heavenly storm of divine swords for 20s that destroys **every monster on the map**!"

| | |
|---|---|
| **Claim** | Every enemy on the map dies |
| **Measured** | **1 of 40 killed** |
| **But** | **60,446 of 120,000 HP** — a fifth of the screen's entire health pool, gone |

The other two Shenron wishes are honest and were left alone: `wish_wealth` really does double drops (`game_manager.gd:924` multiplies by 2 while `golden_frenzy_timer > 0.0`), and `wish_immortality` matches its code line for line.

**The storm was never weak — the copy was.** Measured on 40 enemies at 3000 HP each over the full 20s, it removes 60,446 damage worth. That is enormous. But spread across a whole screen it is ~1,511 damage per enemy against 3,000 HP, so it chips a quarter of everyone's health bar and finishes off whichever one was already hurt. "Toàn bộ ma vật" was the only thing untrue. **Fixed the promise, not the balance** — the description now reads *"Bão Thần Kiếm thiên hà giáng liên tục 20s: mỗi kiếm xuyên 5 mục tiêu, bão đao bào phá diện rộng!"*, which is what `_summon_van_kiem_sword()` actually does. One line, `scripts/game_manager.gd`.

**Why it survived so long: nothing had ever made it falsifiable.** `tests/test_expansion_12.gd` was the only test that touched the wish, and it asserted `player.van_kiem_timer == 20.0` — that a timer got *set*. Not one line of it established that a single enemy took a single point of damage, so a wildly inflated number was perfectly consistent with every green run.

### The check that goes red if either half drifts

`tests/test_shenron_storm.gd` parses the target count **out of the description** and compares it against the blade the wish actually spawns — so it fails if the copy is inflated again *or* if someone retunes `pierce` away from the advertised number. It also pins that one blade puts real damage on the field, and that the description states the 20s it really gets.

### Three harness bugs this suite produced, all mine

*A "proof" that the storm was dead.* The blade is an `Area2D` that deals damage from `body_entered`. The first probe hand-drove `_physics_process()` on every projectile to avoid waiting 20 real seconds — which moves the blade without ever running the physics server. It reported a beautiful, confident **0 damage across 40 enemies**. The storm was working the whole time. The lesson generalises: **when you drive the engine by hand instead of awaiting it, you are measuring your harness.** Real frames (`await get_tree().physics_frame`) fixed it. The suite now says so at the top of `_run_frames()` so the next person does not repeat it.

*A pierce test that proved nothing.* Shooting one blade into a packed formation of 12 and asserting it hit 3+ scored **5, 5, 5, 1** across four runs — the aim point and spawn offset are both randomised. It also could never have caught the regression: because `queue_free()` is deferred to end-of-frame, every body in the pile reports `body_entered` in the same tick the blade dies, so `pierce = 1` still lands three. Replaced with the parsed-promise assertion above. **A check that greens two times out of three is worse than no check** — it teaches people to ignore the gate.

*An assignment that aborted a helper.* Pinning `enemy.has_thunderfire = false` — that is a **Player** field. Assigning it to an Enemy is a runtime error that aborts `_spawn_cluster()` on its first iteration, so the cluster came back empty and two checks failed against nothing. Caught by reading the error rather than the symptom.

**Verification.** Red first: reverting the description returns `CHECK FAILED` with the old string quoted, and collapsing `pierce` 5 → 1 returns `CHECK FAILED` on the parsed number. Both files restored byte-identical via `cmp -s`. Suite green **4/4** consecutive runs (the stability check that the geometric version failed), save md5 unchanged, no stray sidecars. Full gate **53/53** clean three consecutive times.

**Also this pass: a suite the gate had never run.** `scripts/ci.sh` globs `tests/*.tscn`, and `tests/test_gold_and_ui.gd` had no scene beside it — 220 lines of Expansion 6.0 coverage (gold, meta upgrades, SoundManager, weapons, landmarks and shrines, obstacles, world-map UI, save/load, main-scene hierarchy) that had never executed once. An unrun suite is indistinguishable from a passing one. Added the scene, and converted its 72 `assert()` calls to `check()` — otherwise the first failure would have hung it to the 120s timeout while printing its own success banner. It now fails in **2 seconds** reporting **both** of two injected failures 113 lines apart. It also leaked **+941 gold** per standalone run (`start_new_run` / `add_gold` / `buy_meta_upgrade` all reach `save_game_data()`), so it carries the repo's standard `.e6bak` sidecar; save md5 is now identical either side.

---

## Expansion 50.0: "✔ Playtest Session Executed Cleanly With Zero Fatal Errors" (The Bot That Passed Without Playing)

`tests/playtest_player_simulation.gd` is the gate's most expensive suite — 45 seconds of real combat, roughly **a quarter of the entire gate's wall clock**. It ended like this:

```gdscript
print("✔ Playtest session executed cleanly with zero fatal errors.")
get_tree().quit(0)
```

Unconditional. It never asserted anything, so the claim was printed whether or not it was true — including when it was not.

**And it could silently stop being a playtest at all.** The two nodes it needs were fetched behind bare guards:

```gdscript
spawner = main_inst.get_node_or_null("EnemySpawner")
if spawner:
    ...
upgrade_mgr = main_inst.get_node_or_null("UpgradeManager")
if upgrade_mgr:
    ...
```

Rename `EnemySpawner` in `main.tscn` — a perfectly ordinary refactor — and the bot runs its full 45 seconds with **no enemies and no level-ups**, kills nothing, and reports a clean session. Forever after. A playtest bot that cannot detect the player never spawned is failing at the one job it has.

**Four checks, chosen to be unbreakable rather than impressive.** The spawner and the UpgradeManager still resolve; the sim ran its full window; and the bot actually fought. That last one is the load-bearing claim — measured across three runs at **316, 321 and 334 kills** in 45 seconds, against a threshold of `> 0`. A three-hundred-fold margin is not going to flake when someone retunes a weapon; a "kills > 100" threshold would have been.

The "zero fatal errors" line now prints only when there are no failures, and the exit code comes from the failure count rather than from a literal.

**Verification.** Red first, by renaming the node for real: `CHECK FAILED: main.tscn still exposes an EnemySpawner` *and* `CHECK FAILED: The bot actually fought`. Both at once, which is the point — the second check catches what the first one cannot. `scenes/main.tscn` restored byte-identical via `cmp -s`. Also gave the bot the `.playbak` save sidecar its 316 kills were earning into the developer's real save on any hand-run. Full gate **53/53** clean three consecutive times.

Worth recording about my own first attempt at the window check: I wrote `is_equal_approx(sim_time, max_sim_time)` and it failed on a run that had plainly executed all 45 seconds, because accumulated delta lands at 45.000003. The error message printed "stopped at 45.0s" and failed — a confusing artifact of formatting a float to one decimal. It is now a half-second tolerance, which rules out the loop bailing out early rather than arguing about the last bit of a float.

---

## Expansion 51.0: "Hấp Tinh Đại Pháp" (Two Upgrades, One Name, And You Had No Way To Tell)

| Name | Where | What it actually does |
|---|---|---|
| **Lăng Ba Vi Bộ** | level-up card `move_speed` | +15% move speed |
| **Lăng Ba Vi Bộ** | wave-shop scroll `lang_ba_vi_bo` | **+25% speed, −4 armor** |
| **Hấp Tinh Đại Pháp** | level-up card `magnet` | +30% pickup radius |
| **Hấp Tinh Đại Pháp** | wave-shop scroll `hap_tinh_dai_phap` | **+8% lifesteal, −15% max HP** |

Both pairs are buyable **in the same run** — the wave shop opens between waves and the level-up cards arrive during them. A player who took the card and later saw the scroll had nothing to tell them apart by.

It is not only the same word. The magnitudes differ, and worse, **one of each pair carries a downside the other does not**. The scroll's real cost — 4 armour, or 15% of your maximum health — is invisible in a name that reads like a harmless speed upgrade. The two scrolls are renamed: *Phi Hành Thủ Pháp* (speed, costs armour) and *Hút Hồn Thủ Pháp* (lifesteal, costs health). Both stay inside the scroll pool's martial-manual register, and both `id`s are untouched, so nothing downstream moves.

### A sweep found five, and only two were real

Scanning every `"title"` literal across `scripts/` surfaced five duplicate names:

| Name | Verdict |
|---|---|
| `Ma Đạo Huyết Khế` | **Not a bug** — `altar_ui.gd` and `codex_manager.gd` both carry `id: blood_covenant`. The codex entry *documents* that altar; sharing its name is the point. |
| `Kim Cương Bất Hoại` | Daily trial vs. wave-shop scroll. Leaderboard screen vs. in-run shop — never offered side by side. |
| `Vạn Kiếm Quy Tông` | Shenron wish vs. daily trial. Different screens again. |
| `Lăng Ba Vi Bộ`, `Hấp Tinh Đại Pháp` | **Real.** Same run, same screen-moment, different effect. |

Only in-run catalogs are compared, deliberately: demanding global uniqueness would fail for reasons no player can ever hit, and a check that cries wolf gets ignored.

### The detail that would have hidden both of them

The raw strings were never equal. Scroll titles carry a leading emoji — `"🥋 Lăng Ba Vi Bộ"` — and card titles do not. **A plain set-intersection over the two catalogs returned zero collisions with both duplicates sitting right there.** The first sweep reported them as unique until the emoji was stripped.

`tests/test_catalog_titles.gd` compares decoration-free names, and asserts its own normaliser on both halves — because a helper that returned `""` for everything would also find no collisions, which is the same class of bug one level up. It prints its own sample count (`compared 10 card titles against 6 scroll titles`) so a future failure is diagnosable without a second probe.

**Verification.** Red first: restoring the old scroll title returns `'Lăng Ba Vi Bộ' is both level-up card 'move_speed' and wave-shop scroll 'lang_ba_vi_bo'`, naming both ids. `scripts/wave_shop_ui.gd` restored byte-identical via `cmp -s`. No test asserted either display title — `test_wave_arena_redesign.gd` matched the untouched `Kim Cương Bất Hoại` scroll by `id`. Full gate **54/54** clean three consecutive times.

---

## Expansion 52.0: "🔥 Hỏa Thương +50% Sát Thương" (The Daily Trial Advertised Twelve Modifiers And Applied None)

The Daily Celestial Trial panel promised three gameplay modifiers per day — across four challenges, **twelve effects** — and delivered zero of them:

| Challenge | Advertised | Actually happened |
|---|---|---|
| Hỏa Diệm Sơn Khí | `+50%` damage, enemies `+20%` speed | nothing |
| Kim Cương Bất Hoại | shield `x2`, champions `x2` | nothing |
| Vạn Kiếm Quy Tông | cooldown `−30%`, spawns `+40%` | nothing |
| Bát Tiên Túy Võ | dodge `+25%`, goblins `x3` | nothing |

Each row carried a `might_mult` and a `speed_mult` key. **Nothing in the codebase read either one.** The panel at `leaderboard_ui.gd:209` prints `desc` verbatim, so the player was told what the day did to their run, and the day did nothing to their run.

### Why the copy was wrong rather than the code missing

The obvious fix is to wire the keys. That would have been the bigger bug. **There is no trial run to apply them to**: `submit_run()` fires on every run the player finishes, and the payout is for beating today's score. The only wiring that fits is handing every player a silent `+35%` might on that date, with nothing in the HUD explaining where it came from — a change to every run's balance, described only on a screen most players never open. So the copy was corrected and the dead keys deleted. The daily trial is a score-and-reward challenge and now says so.

### The table is a constant now

The four rows moved out of `get_daily_trial_info()` — where they were a literal rebuilt on every call — to `const LeaderboardManager.MUTATORS`, which is what lets a test see all four instead of only the one the calendar picked. That hoist introduces a new hazard, a shared constant a caller could scribble on, so `test_daily_trial.gd` holds both directions:

- **No key goes unread.** Each row is pinned to exactly `{id, title, desc, reward_gold}`; `title`/`desc`/`reward_gold` are separately required to appear as `trial.get("…")` in `leaderboard_ui.gd`, so a key that is allowed but unrendered fails too.
- **No description quotes a number.** The trial modifies no gameplay value, so a digit in these strings is the tell — it promises a magnitude no code path could deliver.
- **The constant survives a caller.** The returned row is stamped with `date`/`completed`/`high_score` after a `.duplicate()`; without it those would land on the constant and leak into every other challenge, turning "CHƯA THAM GIA" into "ĐÃ THAM GIA" for all four.

**Verification.** Red first, twice, with each defect's own signature: re-adding `"might_mult": 1.25` and the old description returned `No challenge row carries a key the game never reads: might_mult on 'fire_surge' is read by nothing` plus both copy failures; dropping the `.duplicate()` returned `Tomorrow's challenge keeps its advertised reward after today's was scribbled on`. `scripts/leaderboard_manager.gd` restored byte-identical via `cmp -s` after each. Full gate **55/55** clean three consecutive times.

---

## Expansion 53.0: "Qi Shield Depleted Appropriately Accounting for Armor" (A Suite That Hung 1 Run In 4 On Whoever You Last Played)

`scripts/ci.sh` snapshots the developer's save and restores it before every suite, so each one starts from real game state and none can leave it changed. That is the right design — and it silently hands all 55 suites **the developer's selected character**, and characters carry stats that `take_damage()` rolls against.

**Tiêu Lãng (Cái Bang Chưởng Môn) has `dodge_bonus: 0.30`.** `player.gd:760` rolls it on every hit. So any suite asserting an exact HP delta through `player.take_damage()` is a **30% coin flip** for a developer who last played the beggar.

Measured, 20 runs each, save restored before every run:

| Save's character | `test_expansion_11` |
|---|---|
| `beggar` (Tiêu Lãng) | **5–6 hangs of 20** |
| `knight` (default) | **0 of 20** |

The failure is worse than a red check. `assert()` aborts the rest of `_ready()`, so the scene never reaches `get_tree().quit()` and the suite **burns the full 120s timeout** — dying on `SCRIPT ERROR: Assertion failed: Qi Shield depleted appropriately accounting for armor`, the dodge having returned early so the shield was never drained.

`test_expansion_11.gd` already documents this exact defect for a *different* half of the same problem ("whenever that save held Ignis (damage_taken_mult 1.15) the shield was correctly drained 15% deeper than this expectation and the assert below failed"). The damage half was fixed. The dodge half was left.

### The fix is one line, in the one place that owns the save

```bash
sed -i 's/^selected_character=.*/selected_character="knight"/' "$SAVE_BACKUP"
```

Applied to the **snapshot**, not the developer's save: the gate still starts every suite from real game state, minus the one field that makes them non-deterministic. `"knight"` is `GameManager.selected_character`'s own default (`game_manager.gd:57`) — the gate picks no hero, it just stops depending on which one you picked. Suites that want a specific character still call `select_character()` and are unaffected.

**Verification.** 0/20 hangs with the pin, 5/20 without, at 27.5% across two separate 20-run samples — the 30% `dodge_bonus`. One thing worth recording: a *single* gate run with the pin stripped still reported `GATE PASSED: 55/55`. At a 30% failure rate that is the expected outcome seven times in ten, and treating it as a pass is exactly the mistake this section exists to prevent — the loop is the evidence, the single green run is not. `scripts/ci.sh` restored byte-identical via `cmp -s` after the strip.

---

## Expansion 54.0: "assert() Only Logs A SCRIPT Error And Keeps Running" (The Reason 638 Assertions Had Never Been Converted)

Fifteen suites — **638 `assert()` calls**, zero `check()` — were excluded from every harness improvement made so far. The stated reason was the mechanical size of the diff. The actual reason was better, and it was written in the code:

> *Godot's assert() only logs a SCRIPT ERROR and keeps running — the process still exits 0, so a suite built on it can never fail a regression run.*

**That is the exact inverse of what the engine does.** Measured 2026-09-30: a failed `assert()` **aborts the rest of the calling function**, so `get_tree().quit()` is never reached, the scene never exits, and the suite hangs until the CI timeout kills it (exit 124). Nobody had converted them because the comment said conversion was unnecessary — and 6 of those files had *already* been converted to `check()`, with the false note copy-pasted above the new harness and left there.

### What it cost

Two failures in one run, not one. The abort masks every later expectation in the same `_ready()` — a stale title assert in `test_expansion_20.gd` was hiding a second, equally stale one. And the gate pays 120s per failing suite; a suite that hangs teaches you nothing about which of its 638 expectations broke.

### The harness, once

20 lines now live in `tests/suite_base.gd` rather than being copied fifteen times. It has no `.tscn`, so `ci.sh`'s `tests/*.tscn` glob never runs it as a suite. A converted suite's entire change:

| | |
|---|---|
| `extends Node` | `extends "res://tests/suite_base.gd"` |
| `assert(cond, msg)` | `check(cond, msg)` |
| banner | wrapped in `if _failures.is_empty():` |
| `get_tree().quit(0)` | `get_tree().quit(_exit_code())` |

The banner guard is not cosmetic. Without it a suite prints `=== ALL EXPANSION 19.0 TESTS PASSED 100% CLEANLY! ===` on a failed run — which is precisely the old bug, reintroduced through the front door.

**Verification.** Two injections, both restored byte-identical via `cmp -s`:

- One failed check in `test_expansion_11`: **rc=1 in 1 second**, naming `Player has 30 Qi Shield capacity`, PASS banner suppressed. Same defect under `assert()`: a 120s hang.
- Two failed checks in `test_expansion_19`, one in the first test function and one in the last: **both reported**, `rc=1`, 1 second. Under `assert()` the first would have aborted `_ready()` and the second would never have run.

Full gate **55/55** clean three consecutive times.

---

## Expansion 55.0: "⚔️ Might / +10% Weapon Damage" (One Scroll List, Three Sections, Two Languages)

`render_shop_items()` (`hud.gd:1205`) builds **one** scroll list with three sections. Two of them were in Vietnamese:

| | |
|---|---|
| section 1 — meta upgrades | `"⚔️ Might"`, `"+10% Weapon Damage"`, `"MAXED"`, `"Buy (250 💰)"`, `"Total Gold: 0 💰"` |
| section 2 — meridians | `"Đả Thông"`, `"Tầng %d/%d"`, `"ĐẠI THÀNH"` |
| section 3 — companions | `"✓ XUẤT TRẬN"`, `"Đổi Linh Thú"` |

Section 1 sat directly above two Vietnamese sections, in the same panel, under a Vietnamese header (`⚒️ TIỆM RÈN & KINH MẠCH`) and a Vietnamese close button (`✖ ĐÓNG (ESC)`). Twelve cards elsewhere had the same shape: Vietnamese `title`, Vietnamese icon, **English `desc`** — a player reading `+2 Armor & Reflect 40% of damage taken` while every other word on the card was Vietnamese.

**21 of the game's 27 card descriptions were in English.** All twelve numbers were verified against the code before being translated, not after: `vitality` `+25` against `_base_max_health()` (`player.gd:464`), `might` `+10%` against `_build_might_bonus()` (`:471`), `magnetism` `+30` against `_base_magnet_radius()` (`:488`), `pyro` `+12%` against the blast rebuild (`:391`), `swiftness` `+20` against `move_speed` (`:357`).

### The rule, and the shape that carries it

The guard is structural, not a list of strings: **a dict literal carrying an `"icon"` key is a card the player reads, and its `desc` must contain a Vietnamese letter.** That is the exact shape relics, companions, meridians and Shenron wishes all have.

Nothing else in the codebase keys off `icon`, which is what makes it free to use as the marker — and which is why "no icon" had to be a *reason* rather than permission. The exemption test pins the icon-less count at **6** (two world-map biome blurbs at `game_manager.gd:119`/`:127`, keyed by `texture_path` and already Vietnamese, plus the four run bounties), so dropping an `icon` off a relic to dodge the rule fails the gate instead.

### Two ways the suite itself lied, and what caught them

- `[^"\\]` in a GDScript string is `[^"\]` to PCRE — an unterminated character class. The suite matched **nothing** and would have gone green forever. Caught by a `found >= 30` canary asserting the regex still finds the literals. (No desc in either file contains a backslash, so `[^"]*` is sufficient.)
- The check `"hud.gd still ships \"Rank %d/%d\""` passed on the *untranslated* string, because the literal in the source is `"%s (Rank %d/%d)\n%s"` — the quoted pattern never matched. A negative string check is only evidence if it can fail; it now matches the bare fragment `(Rank %d/%d)`.

**Verification.** Three injections, all restored byte-identical via `cmp -s`:

| Injection | Result |
|---|---|
| `"+3 HP mỗi khi hạ 10 kẻ địch"` → `"+3 HP every 10 kills"` | `rc=1`, names `game_manager.gd:166` |
| `"⚔️ Cường Lực"` → `"⚔️ Might"` | `rc=1`, names the meta-shop copy |
| `"icon"` → `"relic_art"` on `vampire_fang` (desc left Vietnamese) | `rc=1`, icon-less count 6 → **7** |

Full gate **56/56** clean three consecutive times.

---

## Expansion 56.0: "PYRO: +60%" (The Other Half Of Expansion 45.0)

Expansion 45.0 found that the pause panel reported `MIGHT` as the meta upgrade's term alone, when `_build_might_bonus()` sums four. It fixed that line and the one next to it. **`PYRO` was the same defect, left behind** — and the worst-placed of the six readouts, because pyro is the *smallest* of the six terms in the blast expression at `player.gd:391`:

```gdscript
fire_wpn.blast_radius_multiplier = ((1.0 + char_area_bonus) \
    + GameManager.get_meta_stat("pyro") * 0.12 \
    + float(GameManager.get_meridian_stat("dan_dien") * 0.20) \
    + fire_wpn.run_blast_radius_bonus) * sword_range
```

Six sources. The panel read one.

### Measured, not reasoned

A throwaway probe at **pyro 5 + Đan Điền 3 + Ỷ Thiên Kiếm equipped**:

```
PAUSE PANEL SHOWS: PYRO: +60%
ACTUAL BONUS IS   : PYRO: +175%      (blast_radius_multiplier = 2.75)
understated by   : 115 points
```

The other end of the same bug is worse for trust than for magnitude. A player with **pyro 0 and no meridian** was told they had no AoE bonus at all — `PYRO: +0%` — while every fireball went out 40% wider than base, because Ỷ Thiên Kiếm's `* 1.25` was applied to every shot and appeared on no screen.

### The fix reads the field, not the formula

```gdscript
if player:
	var fire_wpn = player.get_node_or_null("Weapons/FireballWeapon")
	if fire_wpn and "blast_radius_multiplier" in fire_wpn:
		pyro = int(roundf((fire_wpn.blast_radius_multiplier - 1.0) * 100.0))
```

`blast_radius_multiplier` is the one field `fireball_weapon.gd:86` actually multiplies `blast_radius` by, so this cannot drift from `player.gd:391` the way a second copy of the arithmetic would.

The suite reads the **rendered label off a real instantiated HUD** rather than recomputing the expression. A test that duplicated the fixed formula would have passed against the broken panel for as long as the two copies stayed equal — which is the same trap as the `"Rank %d/%d"` check in 55.0.

**Verification.** The fix reverted to the old one-term line, restored byte-identical via `cmp -s`:

```
FAIL: pause panel shows PYRO +60% while the fireball actually fires at +175%
FAIL: with pyro 0 the panel shows PYRO +0% but the blast is +25%
```

Full gate **57/57** clean three consecutive times.

---

## Expansion 57.0: "+40% Né Đòn & +50% Tốc Đánh" (Half An Ultimate Was A Promise With No Code Behind It)

Cái Bang's ultimate advertises two effects. One existed.

| Claimed | Implemented |
|---|---|
| `+40% Né Đòn` | ✅ `player.gd:759` — `+0.40` folded into `total_dodge` whenever `drunken_buff_timer > 0.0` |
| `+50% Tốc Đánh` | ❌ nothing read the timer on the attack-speed path |

It could not have worked. `get_attack_speed_multiplier()` was the **only** attack-speed hook in the game, and its entire body was:

```gdscript
return RELIC_RAGE_ATTACK_SPEED if is_demonic_rage_active() else 1.0
```

No reference to `drunken_buff_timer` — the one function every weapon's fire rate routes through. Measured 2026-10-01 with the beggar applied:

```
attack speed, before = 1
attack speed, during = 1
```

Six seconds of a 6.0-second buff that changed nothing about how fast you attacked.

### One term, not five call sites

All five weapons (`weapon.gd:139`, `axe_weapon.gd:69`, `lightning_weapon.gd:123`, `slash_weapon.gd:157`, `fireball_weapon.gd:110`) already read this one function, so the buff is a second term in its composition rather than five edits:

```gdscript
var mult := 1.0
if is_demonic_rage_active():
	mult *= RELIC_RAGE_ATTACK_SPEED   # 1.15
if drunken_buff_timer > 0.0:
	mult *= 1.50
```

The ternary had to become a composition regardless: a single-source `if/else` is exactly the shape that deletes a source the day a second one arrives.

### A test that asserted arithmetic instead of behaviour

`test_expansion_14.gd:45` already tries to cover this buff's dodge half:

```gdscript
var total_dodge = player.char_dodge_bonus + 0.40
check(total_dodge >= 0.55, "Total dodge reaches 55% during Drunken Brew")
```

That is the test summing two numbers it already knows, not the game rolling a dodge. It would pass if `take_damage()` ignored `drunken_buff_timer` entirely. The new suite calls `get_attack_speed_multiplier()` and compares the value.

**Fixed 2026-10-01.** The dodge half was the half that was left as arithmetic. `test_expansion_14.gd` now rolls it:

```gdscript
player.drunken_buff_timer = 6.0
var buffed_rate := _dodge_rate(player, 300)
check(buffed_rate > 0.58 and buffed_rate < 0.82, "... measured %.1f%%" % (buffed_rate * 100.0))
player.drunken_buff_timer = 0.0
var bare_rate := _dodge_rate(player, 300)
check(bare_rate > 0.20 and bare_rate < 0.40, "... measured %.1f%%" % (bare_rate * 100.0))
```

`_dodge_rate()` calls `Player.take_damage(10.0)` and counts trials where `current_health` did not move, so the only thing it can observe is the real roll at `player.gd:767`. Three inputs are pinned per trial, because all three leave health untouched and would otherwise be scored as a dodge:

| Pinned | Why | Where |
|---|---|---|
| `invulnerability_timer` | a dodge arms a 0.25 s i-frame, a landed hit a 0.35 s one — without clearing it, trial 2 onward returns at the `is_invulnerable` guard and the rate reads ~0 | `player.gd:768`, `:828` |
| `qi_shield_current` | the Nhâm Mạch shield absorbs the whole hit and returns before any health is lost. This is one of the four inputs that leak into every suite through the shared save file | `player.gd:793` |
| `current_health` | topped back up so one hit can't end the run, and so a `phoenix_feather` rebirth (restores health to 40%, then returns) can't fire either | `player.gd:811` |

10.0 damage against 100.0 health is deliberate: `phoenix_feather` only triggers when `final_damage >= current_health`, and this keeps it out of reach.

**Why the bands are where they are.** n = 300 gives σ ≈ 7.9 trials at p = 0.70, so `[0.58, 0.82]` is ~3.7 σ out on the buffed side while the 0.30 an unbuffed beggar rolls sits ~10 σ from the same edge. Both assertions sit far past the combined tail a tighter band would carry, which is what keeps a statistical assertion inside a suite whose other checks are all exact.

**It bites.** Removing just the buff term from `player.gd:766` — leaving the innate 0.30 and the whole `randf() < total_dodge` branch intact — gives the discriminating signature: the buffed assertion reads **28.7 %** and fails, the bare assertion stays green. Only the buff-dependent check moves, which is what makes it a test of the buff rather than of the dodge. The deleted-assertion form could not have done this: `char_dodge_bonus + 0.40` is 0.70 either way, computed entirely from two locals, never reading `player.gd` at all.

**Verification.** The fix reverted to the one-line ternary, restored byte-identical via `cmp -s`:

```
FAIL: Say Rượu Bát Tiên advertises +50% Tốc Đánh; attack speed during the buff is 1.000000
FAIL: rage and the buff compose to 1.725, got 1.150000
```

Full gate **58/58** clean three consecutive times.

---

## Expansion 58.0: A Relic That Only Survived By Luck Of Arrival Order

Chrono Hourglass reads **"Giảm 20% Thời Gian Hồi Chiêu"** and was implemented as a clamp applied exactly once, at pickup:

```gdscript
w.set("speed_multiplier", maxf(float(w.get("speed_multiplier")), 1.25))
```

A floor is a promise about a field's *state*, not about one moment — and `speed_multiplier` has other writers. The hero rebuild subtracts the previous character's `attack_speed_bonus` (`player.gd:254`); the crit shop item multiplies the whole arsenal by 0.85 (`wave_shop_ui.gd:188`). So whether the relic survived depended on nothing but the number it happened to meet.

Measured 2026-10-01, before the fix:

```
A. knight start        : 1
B. + hourglass         : 1.25    <- clamp did the work
F. knight after away+back : 1.25  <- relic SURVIVES
G. ranger start        : 1.35    <- already past the floor
H. + hourglass         : 1.35    <- max(1.35, 1.25) is a no-op, records nothing
I. knight again        : 1.00    <- relic GONE
```

Same relic, same two heroes, opposite outcome. The −20% was simply gone, and no UI ever said so.

### Why a rebuild was the wrong fix

The obvious repair is `speed_multiplier = 1.0 + relic + bonus`. That would **refund every Tốc Đánh card the player bought**: `upgrade_fire_rate` and four card sites accumulate into that same float by `+=`, and the comment at `player.gd:249` already documents the original version of that mistake. The relic's floor is a term, not a base.

### The fix

One helper, `Player._apply_cooldown_floor()`, called by every writer of the field — relic pickup, the hero rebuild, and the shop sweep — so the promise is order-independent instead of a lottery.

**Balance consequence, stated rather than hidden.** Capping the shop penalty means a Knight holding the relic gets no benefit from the crit item's attack-speed cost at all, since 1.25 × 0.85 never gets below 1.25. Leaving the floor out of that path only moves the erasure from *"the hero switch eats the relic"* to *"the hero switch eats the penalty"*. Both promises are player-facing, so the rule is written down at the call site: **the relic is a floor, and the shop penalty is capped by it.**

### A test that passed with the fix deleted

The first version of test 3 was green with the defect present. `player.tscn` puts every instance in group `player`, `wave_shop_ui._get_player()` reads that group, and `queue_free()` in a `_ready()` that never awaits is still pending — so the shop measured a *leftover* player whose field was already floored. Two corrections: `_hero()` now uses `free()` so only one body is ever in the group, and the test asserts `shop._get_player() == p` as a canary so that particular vacuous pass cannot recur.

**Verification.** Both call sites reverted one at a time, restored byte-identical via `cmp -s`:

```
# hero rebuild no longer re-asserts the floor
FAIL: a hero switch must not delete the relic's -20%; got 1.000000
FAIL: pickup above the floor must land on the same value; got 1.250000 then 1.000000

# shop sweep no longer re-asserts the floor
FAIL: one crit upgrade leaves the Knight floored, got 1.062500
FAIL: stacking crit upgrades cannot ratchet the field down, got 0.903125
```

Full gate **59/59** clean three consecutive times.

---

## Expansion 59.0: A Tomb Paid 1 Gold. A Landmark Paid 8.

Two classes, two names for the same thing, and the drop code reached for the wrong one.

| Class | Declares |
|---|---|
| `GoldCoin` (`coin.gd:6`) | `@export var gold_value: int = 1` |
| `Enemy` (`enemy.gd:20`) | `@export var coin_value: int = 1` |

```gdscript
obstacle.gd:49    if coin.has_method("set"):  coin.set("coin_value", 3)   # a tomb
landmark.gd:123   if coin.has_method("set"):  coin.set("coin_value", 5)   # x8, a Vault
```

`Object.set()` on a property the object does not have is a **silent no-op** — no error, no return value, the coin keeps its default. Measured 2026-10-01:

```
gold_value at spawn        : 1
"coin_value" in coin       : false
after set("coin_value", 3) : gold_value = 1   (intent: 3)
after set("gold_value", 3) : gold_value = 3
```

So this could never have been caught by the gate. `scripts/ci.sh` fails a suite on `SCRIPT ERROR:`, and a mistyped property name reports nothing at all — the player's gold simply went missing with no signal anywhere.

### The guard that was worse than no guard

`coin.has_method("set")` fenced both writes. Every `Object` in GDScript has `set()`, so it always passed — including on a coin with no property to write to, which is exactly the case where passing mattered. The check that would have caught this is `"gold_value" in coin`, and it is now the third test in the suite. Both guards are deleted rather than corrected: they cannot fail, so they cannot help.

### Impact, measured

| Source | Paid | Intended | Lost |
|---|---|---|---|
| Tomb (`obstacle.gd:49`) | 1 | 3 | 2 per tomb |
| Vault of the Ancients (`landmark.gd:123`) | 8 | 40 | 32 per landmark |

Losing 32 gold at a single landmark is not a rounding error on a run where a boss scatters 40.

The remaining 25 `set("property", …)` call sites were swept by hand and every one targets a class that declares the property it is given.

**Verification.** Both property names reverted, restored via `sed` and confirmed by grep:

```
FAIL: a tomb is worth 3 gold, got 1 -- the write named a property GoldCoin does not have
FAIL: the Vault is worth 40 gold across its 8 coins, got 8
FAIL: each Vault coin is worth 5, got 1
```

Full gate **60/60** clean three consecutive times.

---

## Expansion 60.0: "👑 GOBLIN SLAIN! +80 GOLD 👑" Paid Zero Long Hồn

### An `elif` that could not fire

`enemy.gd` grants Long Hồn on death — 35 for a boss, 12 for a champion, and:

```gdscript
elif name.begins_with("TreasureGoblin") or enemy_type == "goblin":
	charge_gain = 15.0
```

Neither disjunct can be true:

* `name.begins_with("TreasureGoblin")` — `TreasureGoblin` is its own class (`class_name TreasureGoblin extends CharacterBody2D`) and does **not** extend `Enemy`, so `enemy.gd`'s `die()` never runs for one. The node carrying `goblin.gd` is named `TreasureGoblin`; the node carrying `enemy.gd` is named `Enemy`.
* `enemy_type == "goblin"` — `enemy_type` is not a member of `Enemy` at all. It is a local at `enemy.gd:691`:

```gdscript
var enemy_type = "bat" if is_bat_type else ("skeleton" if name.begins_with("Skeleton") else "")
```

which can only ever hold `"bat"`, `"skeleton"` or `""`. No scene sets it; no code assigns it.

A Treasure Goblin therefore paid **0** Long Hồn — on the loudest kill in a run, the one that announces itself with a banner, drops a guaranteed mega chest, a relic and ten coins, and pays 80 gold.

`ci.sh` could not have caught this either. It greps for `SCRIPT ERROR:`, and an unreachable `elif` reports nothing at all.

### Impact, measured

| Kill | Paid | Intended |
|---|---|---|
| Trash mob | +2.60 (2.0 through a 1.3 harvest multiplier) | 2 |
| **Treasure Goblin** | **0** | **15** |
| Champion | +15.60 (12.0 through the same 1.3) | 12 |
| Boss | +45.50 (35.0 through the same 1.3) | 35 |

### The fix

It moved into `goblin.gd`, where the death actually happens, and the dead `elif` is deleted rather than left behind as a comment-shaped trap:

```gdscript
func _award_dragon_soul() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("add_dragon_soul"):
		p.add_dragon_soul(15.0)
```

Split out of `die()` deliberately: the payout above it runs through `GameManager.add_gold()`, which calls `save_game_data()` with no suppression switch, so this is the only part of a goblin's death a suite can measure without writing outside the repository.

**What the suite does not prove.** It never calls `die()`. It proves the award pays 15, not that `die()` invokes it — the trade-off is real and is stated in `tests/test_expansion_60.gd`. `die()` calling `_award_dragon_soul()` is one line and both are greppable; the number itself lives in exactly one place.

**Verification.** With the award removed, three assertions read `0.00`.

Full gate **61/61** clean three consecutive times.

---

## Expansion 60.1: The Gate Stopped Reading And Writing Your Save

### What `XDG_DATA_HOME` actually does on Linux

The comment in `ci.sh` claimed Godot "ignores XDG_DATA_HOME" for `user://`. It does not. Measured 2026-10-02 by running one suite with `XDG_DATA_HOME` set to a repository-local directory and finding `save_data.cfg` written there. Ten suites write to that file and one spends gold, so it is the whole reason the gate reached outside the project.

```bash
CI_USERDATA="${CI_USERDATA:-$PROJECT_DIR/.ci_userdata}"
export XDG_DATA_HOME="$CI_USERDATA"
mkdir -p "$XDG_DATA_HOME/godot/app_userdata"
```

`.ci_userdata/` is added to `.gitignore`.

### The blank save is the same state the old pin faked

Expansion 37.1 snapshotted the developer's real save and restored it between suites; Expansion 53.0 added a `sed` pin for `selected_character`. Both existed to force one specific starting state. Deleting the scratch save between suites forces the same state for free, and states it in two lines of `game_manager.gd` rather than in shell:

| Field | Blank value | Source |
|---|---|---|
| `selected_character` | `"knight"` | `game_manager.gd:57` |
| `total_gold` | `0` | `game_manager.gd:56` |

The knight default is the load-bearing one, and it is why the `sed` pin is no longer needed.

### Two suites were passing on the wrong save

Making the gate hermetic surfaced two latent dependencies the snapshot had been covering.

**`test_expansion_24` waited on the wrong property.** Its three DoT preconditions did a fixed `await _physics_frames(40)`. 40 ticks is 0.667s against a 0.4s burn — ample, unless something re-applies the effect mid-wait. `_freeze_player_weapons()` disables the weapon *nodes*, but a projectile already in flight is parented to `current_scene`, not to the weapon (`fireball_weapon.gd:94`), and keeps firing: `fireball_projectile.gd:63` re-applies a **3.5s** burn on impact. Whether one is mid-flight is pure frame timing — 2 of 8 runs failed.

Waiting on `burn_timer` alone was not enough either. `enemy.gd:182-188` zeroes `burn_dps` in the same tick the timer crosses zero, so a fireball landing one frame after that crossing puts the rate straight back to 40 and the precondition still reads a stale value — 1 of 12. The wait is now on both properties at once, because that joint condition is what "the effect has been handed back" actually means:

```gdscript
func _await_handed_back(node: Node, timer_prop: String, rate_prop: String, max_frames: int = 600) -> void:
	for _i in max_frames:
		if float(node.get(timer_prop)) <= 0.0 and float(node.get(rate_prop)) <= 0.0:
			return
		await get_tree().physics_frame
```

20 of 20 runs clean, from 1 in 12.

**`test_wave_arena_milestone_2:414` inherited the developer's armour.** `_taken_by()` zeroes `char_armor_bonus` and `shop_armor_bonus` — two of the four terms `get_armor_bonus()` sums (`player.gd:946-949`). The other two come from the save and are not player members at all:

```gdscript
var meta_arm = GameManager.get_meta_stat("armor") if GameManager else 0
var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
```

So a knight lost **28** on a save with the Nhuyễn Vị Giáp relic and exactly **30** on a blank one, and the assertion was `knight_loss < 30.0`. It was never about 30; it was a proxy for "a hit is not fully absorbed" that held only for whoever was last played. The ratio check one line above is unaffected, since both heroes share whatever armour is equipped — which is why only the absolute one failed.

`_taken_by()` now reads the armour back rather than assuming it, and the assertion is exact on any save:

```gdscript
check(is_equal_approx(knight_loss, maxf(1.0, 30.0 - float(knight_taken.y))),
	"The full damage path still runs: 30 less the armour it actually had (lost %.2f at %d armour)"
	% [knight_loss, int(knight_taken.y)])
```

**Verification.** Full gate **61/61** clean three consecutive times, from a scratch save inside the repository.

---

## Running the Game

```bash
# Launch the game directly:
~/.local/bin/godot --path /home/renovibe79/survivors-game

# Or open the visual editor:
~/.local/bin/godot --editor --path /home/renovibe79/survivors-game
```

## Exporting for Web

```bash
/home/renovibe79/survivors-game/export_web.sh
```
This produces `build/survivorquest_web.zip`, which you can upload directly to **itch.io** or submit to **CrazyGames Developer Portal**.
