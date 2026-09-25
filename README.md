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
