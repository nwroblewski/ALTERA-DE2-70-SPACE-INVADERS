LIBRARY  ieee;
USE ieee.std_logic_1164.all;
 
 
entity GAME_VGA is
    port(
 
--------------------------- INPUTS ---------------------------
        in_clk_50 : in std_logic; -- vga clock
        in_clk_28: in std_logic;
        in_key_left: in std_logic;
        in_key_shoot: in std_logic;
        in_key_right: in std_logic;
        in_key_restart : in std_logic;
 
--------------------------- OUTPUTS ---------------------------
        out_h_sync : out std_logic;  -- horizontal sync
        out_v_sync : out std_logic;  -- vertical sync
        out_R :  out std_logic_vector(9 downto 0);
        out_G :  out std_logic_vector(9 downto 0);
        out_B :  out std_logic_vector(9 downto 0);
        out_blank : out std_logic;
        out_sync : out std_logic;
        out_clk : out std_logic
        );
 
end GAME_VGA;
 
 
architecture DRAWING_LOGIC of GAME_VGA is
 
--------------------------- HORIZONTAL (X) TIMING ---------------------------
    constant H_VA : natural := 640; -- visible area
    constant H_FP : natural := 16; -- front porch
    constant H_SP : natural := 96; -- sync pulse
    constant H_TOTAL : natural := 800; -- whole line
 
    signal h_sync_enable: std_logic;
 
   
--------------------------- VERTICAL (Y) TIMING ---------------------------
    constant V_VA : natural := 480; -- visible area
    constant V_FP : natural := 10; -- front porch
    constant V_SP : natural := 2; -- sync pulse
    constant V_TOTAL : natural := 525; -- whole frame
 
    signal v_sync_enable: std_logic;
 
 
--------------------------- DRAWING VARIABLES ---------------------------
    signal x: integer range 0 to 800 := 0;
    signal y: integer range 0 to 525 := 0;
 
 
--------------------------- SYNCHRONIZATION ---------------------------
    signal half_clock: std_logic;
    signal animation_clk: std_logic;
    signal clk_divider: integer range 0 to 7000000 := 0; -- ?????
   
 
--------------------------- PLAYER ---------------------------
    signal player_offset: integer range 0 to 500 := 0;
    constant player_speed : natural := 6;
    signal player_alive: integer range 0 to 2 := 2;
 
 
--------------------------- ALIEN ---------------------------
    signal alive: std_logic_vector(14 downto 0) := "111111101111111";
 
    constant alien1_x0: natural := 70;
    constant alien1_x1: natural := 110;
    constant alien1_y0: natural := 50;
    constant alien1_y1: natural := 90;
 
    constant alien2_x0: natural := 140;
    constant alien2_x1: natural := 180;
    constant alien2_y0: natural := 50;
    constant alien2_y1: natural := 90;
    
    constant alien3_x0: natural := 210;
    constant alien3_x1: natural := 250;
    constant alien3_y0: natural := 50;
    constant alien3_y1: natural := 90;
 
	constant alien4_x0: natural := 280;
    constant alien4_x1: natural := 320;
    constant alien4_y0: natural := 50;
    constant alien4_y1: natural := 90;
 
	constant alien5_x0: natural := 350;
    constant alien5_x1: natural := 390;
    constant alien5_y0: natural := 50;
    constant alien5_y1: natural := 90;
    
    constant alien6_x0: natural := 420;
    constant alien6_x1: natural := 460;
    constant alien6_y0: natural := 50;
    constant alien6_y1: natural := 90;
    
    constant alien7_x0: natural := 490;
    constant alien7_x1: natural := 530;
    constant alien7_y0: natural := 50;
    constant alien7_y1: natural := 90;
    
    constant alien8_x0: natural := 560;
    constant alien8_x1: natural := 600;
    constant alien8_y0: natural := 50;
    constant alien8_y1: natural := 90;
    
    constant alien9_x0: natural := 70;
    constant alien9_x1: natural := 110;
    constant alien9_y0: natural := 120;
    constant alien9_y1: natural := 160;
 
    constant alien10_x0: natural := 140;
    constant alien10_x1: natural := 180;
    constant alien10_y0: natural := 120;
    constant alien10_y1: natural := 160;
    
    constant alien11_x0: natural := 210;
    constant alien11_x1: natural := 250;
    constant alien11_y0: natural := 120;
    constant alien11_y1: natural := 160;
    
    constant alien12_x0: natural := 280;
    constant alien12_x1: natural := 320;
    constant alien12_y0: natural := 120;
    constant alien12_y1: natural := 160;
    
    constant alien13_x0: natural := 350;
    constant alien13_x1: natural := 390;
    constant alien13_y0: natural := 120;
    constant alien13_y1: natural := 160;
    
    constant alien14_x0: natural := 420;
    constant alien14_x1: natural := 460;
    constant alien14_y0: natural := 120;
    constant alien14_y1: natural := 160;
    
    constant alien15_x0: natural := 490;
    constant alien15_x1: natural := 530;
    constant alien15_y0: natural := 120;
    constant alien15_y1: natural := 160;
    
--------------------------- BULLET AND SHOOTING ---------------------------
    signal bullet_x_position: integer range 0 to 500:= 0; -- when shooting key is pressed
    signal bullet_offset: integer range 0 to 5000 := 0;
    signal can_shoot: integer range 0 to 1 := 1;
    constant bullet_speed: natural := 6;    
    signal bullet_visibility: integer range 0 to 1 := 0;
    
--------------------------- ALIEN SHOOTINGS -----------------------
	signal evil_x_position: integer range 10 to 620 := 10;
	signal evil_offset: integer range 0 to 5000 := 0;
	signal evil_can_shoot: integer range 0 to 1 := 1;
	signal evil_visibility: integer range 0 to 1 := 0;
	signal evil_x_snapshot: integer range 10 to 620 := 10;
	constant evil_bullet_speed: natural := 10;
 
 
    begin
        out_sync <= '0';
        out_blank <= '1';
        out_h_sync <= h_sync_enable;
        out_v_sync <= v_sync_enable;
        out_clk <= half_clock;
       
 
    -- HALFING THE CLOCK --
    CLOCK_SCALE: process(in_clk_50)
    begin
        if in_clk_50'event and in_clk_50 = '1' then
            half_clock <= not half_clock;
        end if;
    end process CLOCK_SCALE;
   
 
 
    DIVIDE_FREQUENCY: process(in_clk_28)
    begin
        if in_clk_28'event and in_clk_28 = '1' then
            if clk_divider = 350000 then
                clk_divider <= 0;
                animation_clk <= not animation_clk;
            else
                clk_divider <= clk_divider + 1;
            end if;
        end if;
    end process DIVIDE_FREQUENCY;
   
   
 
    DRAWING: process(half_clock)
    begin
        if half_clock'event and half_clock = '1' then
            if x = H_TOTAL then
                x <= 0;
                y <= y + 1;
                if y = V_TOTAL then
                    y <= 0;
                else
                    y <= y + 1;
                end if;
            else
                x <= x + 1;
            end if;
        end if;
    end process DRAWING;
 
	-- RANDOMIZING EVIL SHOT X --
	RAND_X: process(in_clk_50)
    begin
		if rising_edge(in_clk_50) then
			if evil_x_position = 620 then
				evil_x_position <= 10;
			else
				evil_x_position <= evil_x_position + 2;
			end if;
		end if;
	end process RAND_X;
	
	
	EVIL_BULLET_MOVE: process(animation_clk)
    begin
        if animation_clk'event and animation_clk = '1' then
            if evil_can_shoot = 0 then
                evil_offset <= evil_offset + evil_bullet_speed;
            else
                evil_offset <= 0;
            end if;
        end if;
    end process EVIL_BULLET_MOVE;
	
	
	
	SHOOT_AND_PLAYER_KILL: process(animation_clk)
    begin	
		if rising_edge(animation_clk) then
           if (evil_can_shoot = 1) then
				evil_visibility <= 1;
				evil_can_shoot <= 0;
				evil_x_snapshot <= evil_x_position;
		   elsif (170 + evil_offset > 480) then
				evil_can_shoot <= 1;
				evil_visibility <= 0;
		   elsif (((evil_x_snapshot - 5 > player_offset and evil_x_snapshot - 5 < player_offset + 37) or (evil_x_snapshot + 5 > player_offset and evil_x_snapshot + 5 < player_offset + 37)) and (170 + evil_offset > 392 and player_alive > 0 and evil_visibility = 1)) then
				player_alive <= player_alive - 1;
				evil_can_shoot <= 1;
				evil_visibility <= 0;
		   elsif (in_key_restart = '0') then
				player_alive <= 2;
		   end if;
		end if;
	end process SHOOT_AND_PLAYER_KILL;
	
	
    SHOOT_AND_KILL: process(in_key_shoot)
    begin
        if rising_edge(animation_clk) then
            if (in_key_shoot = '0' and can_shoot = 1) then
                bullet_visibility <= 1;
                can_shoot <= 0;
                bullet_x_position <= player_offset;
            elsif (380 - bullet_offset < 0) then
                bullet_visibility <= 0;
                can_shoot <= 1;
            elsif (alien1_x0 < (4 + bullet_x_position + 11) and alien1_x1 > (33 + bullet_x_position - 11) and alien1_y1 > 380 - bullet_offset and alive(0) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(0) <= '0';
            elsif (alien2_x0 < (4 + bullet_x_position + 11) and alien2_x1 > (33 + bullet_x_position - 11) and alien2_y1 > 380 - bullet_offset and alive(1) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(1) <= '0';
            elsif (alien3_x0 < (4 + bullet_x_position + 11) and alien3_x1 > (33 + bullet_x_position - 11) and alien3_y1 > 380 - bullet_offset and alive(2) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(2) <= '0';
            elsif (alien4_x0 < (4 + bullet_x_position + 11) and alien4_x1 > (33 + bullet_x_position - 11) and alien4_y1 > 380 - bullet_offset and alive(3) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(3) <= '0';
            elsif (alien5_x0 < (4 + bullet_x_position + 11) and alien5_x1 > (33 + bullet_x_position - 11) and alien5_y1 > 380 - bullet_offset and alive(4) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(4) <= '0';
            elsif (alien6_x0 < (4 + bullet_x_position + 11) and alien6_x1 > (33 + bullet_x_position - 11) and alien6_y1 > 380 - bullet_offset and alive(5) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(5) <= '0';
            elsif (alien7_x0 < (4 + bullet_x_position + 11) and alien7_x1 > (33 + bullet_x_position - 11) and alien7_y1 > 380 - bullet_offset and alive(6) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(6) <= '0';
            elsif (alien8_x0 < (4 + bullet_x_position + 11) and alien8_x1 > (33 + bullet_x_position - 11) and alien8_y1 > 380 - bullet_offset and alive(7) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(7) <= '0';
            elsif (alien9_x0 < (4 + bullet_x_position + 11) and alien9_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(8) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(8) <= '0';
            elsif (alien10_x0 < (4 + bullet_x_position + 11) and alien10_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(9) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(9) <= '0';
			elsif (alien11_x0 < (4 + bullet_x_position + 11) and alien11_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(10) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(10) <= '0';
            elsif (alien12_x0 < (4 + bullet_x_position + 11) and alien12_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(11) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(11) <= '0';
            elsif (alien13_x0 < (4 + bullet_x_position + 11) and alien13_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(12) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(12) <= '0';
            elsif (alien14_x0 < (4 + bullet_x_position + 11) and alien14_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(13) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(13) <= '0';
            elsif (alien15_x0 < (4 + bullet_x_position + 11) and alien15_x1 > (33 + bullet_x_position - 11) and alien9_y1 > 380 - bullet_offset and alive(14) = '1') then
                bullet_visibility <= 0;
                can_shoot <= 1;
                alive(14) <= '0';
            elsif (in_key_restart = '0') then
				alive <= (others => '1');
				alive(7) <= '0';
            end if;
        end if;
       
--          if (bullet_visibility = '1' and can_shoot = 0) then
--             
    end process SHOOT_AND_KILL;
   
   
   
    BULLET_MOVE: process(animation_clk)
    begin
        if animation_clk'event and animation_clk = '1' then
            if can_shoot = 0 then
                bullet_offset <= bullet_offset + bullet_speed;
            else
                bullet_offset <= 0;
            end if;
        end if;
    end process BULLET_MOVE;
       
       
   
    PLAYER_MOVE: process(in_key_left, in_key_right)
    begin
        if rising_edge(animation_clk) then
            if in_key_left = '0' then
                player_offset <= player_offset - player_speed;
            end if;
            if in_key_right = '0' then
                player_offset <= player_offset + player_speed;
            end if;
        end if;
    end process PLAYER_MOVE;
   
 
 
    VGA_SYNC: process (half_clock)
    begin
        if half_clock'event and half_clock = '1' then
            if x >= (H_VA + H_FP) and x < (H_VA + H_FP + H_SP) then
                h_sync_enable <= '0';
            else
                h_sync_enable <= '1';
            end if;
           
            if y >= (V_VA + V_FP) and y < (V_VA + V_FP + V_SP) then
                v_sync_enable <= '0';
            else
                v_sync_enable <= '1';
            end if;
        end if;
    end process VGA_SYNC;
 
       
 
    DRAW_GAMEBOARD: process(half_clock)
    begin
        if half_clock'event and half_clock = '1' then
 
            if( x > 0 + player_offset and x < 37 + player_offset and y > 400 and y < 405 and x < 640 and y < 480 and player_alive > 0) then
                out_R(9) <= '0';
                out_G(9) <= '1';
                out_B(9) <= '1';
            elsif(x > 4 + player_offset and x < 33 + player_offset  and y > 392 and y < 401 and player_alive > 0) then
                out_R(9) <= '0';
                out_G(9) <= '1';
                out_B(9) <= '1';
            elsif(x > (4 + bullet_x_position + 11) and x < (33 + bullet_x_position - 11) and y < 392 - bullet_offset and y > 380 - bullet_offset and y > 0 and bullet_visibility = 1 and can_shoot = 0 and player_alive > 0) then
                out_R(9) <= '1';
                out_G(9) <= '0';
                out_B(9) <= '0';
            elsif(x > alien1_x0 and x < alien1_x1 and y > alien1_y0 and y < alien1_y1 and alive(0) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien2_x0 and x < alien2_x1 and y > alien2_y0 and y < alien2_y1 and alive(1) = '1') then
                out_R <= (others => '1');
                out_G <= (others=> '1');
                out_B <= (others => '1');
            elsif(x > alien3_x0 and x < alien3_x1 and y > alien3_y0 and y < alien3_y1 and alive(2) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien4_x0 and x < alien4_x1 and y > alien4_y0 and y < alien4_y1 and alive(3) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien5_x0 and x < alien5_x1 and y > alien5_y0 and y < alien5_y1 and alive(4) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien6_x0 and x < alien6_x1 and y > alien6_y0 and y < alien6_y1 and alive(5) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien7_x0 and x < alien7_x1 and y > alien7_y0 and y < alien7_y1 and alive(6) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien8_x0 and x < alien8_x1 and y > alien8_y0 and y < alien8_y1 and alive(7) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien9_x0 and x < alien9_x1 and y > alien9_y0 and y < alien9_y1 and alive(8) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien10_x0 and x < alien10_x1 and y > alien10_y0 and y < alien10_y1 and alive(9) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien11_x0 and x < alien11_x1 and y > alien11_y0 and y < alien11_y1 and alive(10) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien12_x0 and x < alien12_x1 and y > alien12_y0 and y < alien12_y1 and alive(11) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien13_x0 and x < alien13_x1 and y > alien13_y0 and y < alien13_y1 and alive(12) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien14_x0 and x < alien14_x1 and y > alien14_y0 and y < alien14_y1 and alive(13) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > alien15_x0 and x < alien15_x1 and y > alien15_y0 and y < alien15_y1 and alive(14) = '1') then
                out_R <= (others => '1');
                out_G <= (others => '1');
                out_B <= (others => '1');
            elsif(x > evil_x_snapshot - 5 and x < evil_x_snapshot + 5 and y > 170 + evil_offset and y < 178 + evil_offset and evil_visibility = 1) then
				out_R <= (others => '0');
                out_G <= (others => '0');
                out_B <= (others => '1');
            elsif(x > 100 and x < 120 and y > 450 and y < 470 and player_alive > 1) then
				out_R <= (others => '1');
                out_G <= (others => '0');
                out_B <= (others => '0');
            elsif(x > 150 and x < 170 and y > 450 and y < 470 and player_alive > 0) then
				out_R <= (others => '1');
                out_G <= (others => '0');
                out_B <= (others => '0');
            else
                out_R <= (others => '0');
                out_G <= (others => '0');
                out_B <= (others => '0');
            end if;
        end if;
    end process DRAW_GAMEBOARD;
           
end DRAWING_LOGIC;