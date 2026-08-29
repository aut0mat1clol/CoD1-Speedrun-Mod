main()
{
}

get_name(override)
{
	if (!isdefined (override))
	{
		if ((level.script == "stalingrad") || (level.script == "stalingrad_nolight"))
			return;
		if (level.script == "credits")
			return;
	}
	
	if (isdefined (self.script_friendname))
	{
		self.name = self.script_friendname;
		return;
	}		
	
	american_names 	= 150;
	british_names 	= 141;
	russian_names 	= 139;
	
	if ( !(isdefined (game["americannames"]) ) )
		game["americannames"] = randomint (american_names);
	if ( !(isdefined (game["britishnames"]) ) )
		game["britishnames"] = randomint (british_names);
	if ( !(isdefined (game["russiannames"]) ) )
		game["russiannames"] = randomint (russian_names);


	if (level.campaign == "british")
	{
		game["britishnames"]++;
		get_british_name();
	}
	else
	if (level.campaign == "russian")
	{
		game["russiannames"]++;
		get_russian_name();
	}
	else
	{
		game["americannames"]++;
		get_american_name();
	}
}

get_american_name()
{
	switch (game["americannames"])
	{
		case  1: self.name = "Ericg08";break;
		case  2: self.name = "Soupsake";break;
		case  3: self.name = "Klooger";break;
		case  4: self.name = "Danza";break;
		case  5: self.name = "Bluetarget";break;
		case  6: self.name = "mozyakin";break;
		case  7: self.name = "Matyop20";break;
		case  8: self.name = "Liserd";break;
		case  9: self.name = "aut0mat1clol";break;
		case 10: self.name = "rythin";break;
		case 11: self.name = "Whose";break;
		case 12: self.name = "DarkSR";break;
		case 13: self.name = "Churp";break;
		case 14: self.name = "nehyzo";break;
		case 15: self.name = "Aaron";break;
		case 16: self.name = "SuperFull";break;
		case 17: self.name = "first_try_i_swear";break;
		case 18: self.name = "Zayido";break;
		case 19: self.name = "iden";break;
		case 20: self.name = "Fish";break;
		case 21: self.name = "medzii";break;
		case 22: self.name = "Surviv0r";break;
		case 23: self.name = "Ericg08";break;
		case 24: self.name = "Soupsake";break;
		case 25: self.name = "Klooger";break;
		case 26: self.name = "Danza";break;
		case 27: self.name = "Bluetarget";break;
		case 28: self.name = "mozyakin";break;
		case 29: self.name = "Matyop20";break;
		case 30: self.name = "Liserd";break;
		case 31: self.name = "aut0mat1clol";break;
		case 32: self.name = "rythin";break;
		case 33: self.name = "Whose";break;
		case 34: self.name = "DarkSR";break;
		case 35: self.name = "Churp";break;
		case 36: self.name = "nehyzo";break;
		case 37: self.name = "Aaron";break;
		case 38: self.name = "SuperFull";break;
		case 39: self.name = "first_try_i_swear";break;
		case 40: self.name = "Zayido";break;
		case 41: self.name = "iden";break;
		case 42: self.name = "Fish";break;
		case 43: self.name = "medzii";break;
		case 44: self.name = "Surviv0r";break;
		case 45: self.name = "Ericg08";break;
		case 46: self.name = "Soupsake";break;
		case 47: self.name = "Klooger";break;
		case 48: self.name = "Danza";break;
		case 49: self.name = "Bluetarget";break;
		case 50: self.name = "mozyakin";break;
		case 51: self.name = "Matyop20";break;
		case 52: self.name = "Liserd";break;
		case 53: self.name = "aut0mat1clol";break;
		case 54: self.name = "rythin";break;
		case 55: self.name = "Whose";break;
		case 56: self.name = "DarkSR";break;
		case 57: self.name = "Churp";break;
		case 58: self.name = "nehyzo";break;
		case 59: self.name = "Aaron";break;
		case 60: self.name = "SuperFull";break;
		case 61: self.name = "first_try_i_swear";break;
		case 62: self.name = "Zayido";break;
		case 63: self.name = "iden";break;
		case 64: self.name = "Fish";break;
		case 65: self.name = "medzii";break;
		case 66: self.name = "Surviv0r";break;
		case 67: self.name = "Ericg08";break;
		case 68: self.name = "Soupsake";break;
		case 69: self.name = "Klooger";break;
		case 70: self.name = "Danza";break;
		case 71: self.name = "Bluetarget";break;
		case 72: self.name = "mozyakin";break;
		case 73: self.name = "Matyop20";break;
		case 74: self.name = "Liserd";break;
		case 75: self.name = "aut0mat1clol";break;
		case 76: self.name = "rythin";break;
		case 77: self.name = "Whose";break;
		case 78: self.name = "DarkSR";break;
		case 79: self.name = "Churp";break;
		case 80: self.name = "nehyzo";break;
		case 81: self.name = "Aaron";break;
		case 82: self.name = "SuperFull";break;
		case 83: self.name = "first_try_i_swear";break;
		case 84: self.name = "Zayido";break;
		case 85: self.name = "iden";break;
		case 86: self.name = "Fish";break;
		case 87: self.name = "medzii";break;
		case 88: self.name = "Surviv0r";break;
		case 89: self.name = "Ericg08";break;
		case 90: self.name = "Soupsake";break;
		case 91: self.name = "Klooger";break;
		case 92: self.name = "Danza";break;
		case 93: self.name = "Bluetarget";break;
		case 94: self.name = "mozyakin";break;
		case 95: self.name = "Matyop20";break;
		case 96: self.name = "Liserd";break;
		case 97: self.name = "aut0mat1clol";break;
		case 98: self.name = "rythin";break;
		case 99: self.name = "Whose";break;
		case 100: self.name = "DarkSR";break;
		case 101: self.name = "Churp";break;
		case 102: self.name = "nehyzo";break;
		case 103: self.name = "Aaron";break;
		case 104: self.name = "SuperFull";break;
		case 105: self.name = "first_try_i_swear";break;
		case 106: self.name = "Zayido";break;
		case 107: self.name = "iden";break;
		case 108: self.name = "Fish";break;
		case 109: self.name = "medzii";break;
		case 110: self.name = "Surviv0r";break;
		case 111: self.name = "Ericg08";break;
		case 112: self.name = "Soupsake";break;
		case 113: self.name = "Klooger";break;
		case 114: self.name = "Danza";break;
		case 115: self.name = "Bluetarget";break;
		case 116: self.name = "mozyakin";break;
		case 117: self.name = "Matyop20";break;
		case 118: self.name = "Liserd";break;
		case 119: self.name = "aut0mat1clol";break;
		case 120: self.name = "rythin";break;
		case 121: self.name = "Whose";break;
		case 122: self.name = "DarkSR";break;
		case 123: self.name = "Churp";break;
		case 124: self.name = "nehyzo";break;
		case 125: self.name = "Aaron";break;
		case 126: self.name = "SuperFull";break;
		case 127: self.name = "first_try_i_swear";break;
		case 128: self.name = "Zayido";break;
		case 129: self.name = "iden";break;
		case 130: self.name = "Fish";break;
		case 131: self.name = "medzii";break;
		case 132: self.name = "Surviv0r";break;
		case 133: self.name = "Ericg08";break;
		case 134: self.name = "Soupsake";break;
		case 135: self.name = "Klooger";break;
		case 136: self.name = "Danza";break;
		case 137: self.name = "Bluetarget";break;
		case 138: self.name = "mozyakin";break;
		case 139: self.name = "Matyop20";break;
		case 140: self.name = "Liserd";break;
		case 141: self.name = "aut0mat1clol";break;
		case 142: self.name = "rythin";break;
		case 143: self.name = "Whose";break;
		case 144: self.name = "DarkSR";break;
		case 145: self.name = "Churp";break;
		case 146: self.name = "nehyzo";break;
		case 147: self.name = "Aaron";break;
		case 148: self.name = "SuperFull";break;
		case 149: self.name = "first_try_i_swear";break;
		case 150: self.name = "Om Nom"; game["americannames"] = 0;break;
	}

	if (self.weapon == "thompson")
		self.name = "Lt. " + self.name;
	else
	{
		rank = randomint (100);
		if (rank > 40)
			self.name = "Pvt. " + self.name;
		else
		if (rank > 20)
			self.name = "Cpl. " + self.name;
		else
			self.name = "Sgt. " + self.name;
	}
}

get_british_name()
{
	switch (game["britishnames"])
	{
		case  1: self.name = "Pvt. Ericg08";break;
		case  2: self.name = "Sgt. Soupsake";break;
		case  3: self.name = "Pvt. Klooger";break;
		case  4: self.name = "Pvt. Danza";break;
		case  5: self.name = "Pvt. Bluetarget";break;
		case  6: self.name = "Pvt. mozyakin";break;
		case  7: self.name = "Pvt. Matyop20";break;
		case  8: self.name = "Pvt. Liserd";break;
		case  9: self.name = "Pvt. aut0mat1clol";break;
		case  10: self.name = "Pvt. rythin";break;
		case  11: self.name = "Pvt. Whose";break;
		case  12: self.name = "Pvt. DarkSR";break;
		case  13: self.name = "Pvt. Churp";break;
		case  14: self.name = "Pvt. nehyzo";break;
		case  15: self.name = "Pvt. Aaron";break;
		case  16: self.name = "Pvt. SuperFull";break;
		case  17: self.name = "Pvt. first_try_i_swear";break;
		case  18: self.name = "Pvt. Zayido";break;
		case  19: self.name = "Pvt. iden";break;
		case  20: self.name = "Pvt. Fish";break;
		case  21: self.name = "Pvt. medzii";break;
		case  22: self.name = "Pvt. Surviv0r";break;
		case  23: self.name = "Pvt. Ericg08";break;
		case  24: self.name = "Pvt. Soupsake";break;
		case  25: self.name = "Pvt. Klooger";break;
		case  26: self.name = "Pvt. Danza";break;
		case  27: self.name = "Pvt. Bluetarget";break;
		case  28: self.name = "Pvt. mozyakin";break;
		case  29: self.name = "Pvt. Matyop20";break;
		case  30: self.name = "Pvt. Liserd";break;
		case  31: self.name = "Pvt. aut0mat1clol";break;
		case  32: self.name = "Pvt. rythin";break;
		case  33: self.name = "Pvt. Whose";break;
		case  34: self.name = "Pvt. DarkSR";break;
		case  35: self.name = "Pvt. Churp";break;
		case  36: self.name = "Pvt. nehyzo";break;
		case  37: self.name = "Pvt. Aaron";break;
		case  38: self.name = "Pvt. SuperFull";break;
		case  39: self.name = "Pvt. first_try_i_swear";break;
		case  40: self.name = "Pvt. Zayido";break;
		case  41: self.name = "Pvt. iden";break;
		case  42: self.name = "Pvt. Fish";break;
		case  43: self.name = "Pvt. medzii";break;
		case  44: self.name = "Pvt. Surviv0r";break;
		case  45: self.name = "Pvt. Ericg08";break;
		case  46: self.name = "Pvt. Soupsake";break;
		case  47: self.name = "Pvt. Klooger";break;
		case  48: self.name = "Pvt. Danza";break;
		case  49: self.name = "Pvt. Bluetarget";break;
		case  50: self.name = "Pvt. mozyakin";break;
		case  51: self.name = "Pvt. Matyop20";break;
		case  52: self.name = "Pvt. Liserd";break;
		case  53: self.name = "Pvt. aut0mat1clol";break;
		case  54: self.name = "Pvt. rythin";break;
		case  55: self.name = "Pvt. Whose";break;
		case  56: self.name = "Pvt. DarkSR";break;
		case  57: self.name = "Pvt. Churp";break;
		case  58: self.name = "Pvt. nehyzo";break;
		case  59: self.name = "Pvt. Aaron";break;
		case  60: self.name = "Pvt. SuperFull";break;
		case  61: self.name = "Pvt. first_try_i_swear";break;
		case  62: self.name = "Pvt. Zayido";break;
		case  63: self.name = "Pvt. iden";break;
		case  64: self.name = "Pvt. Fish";break;
		case  65: self.name = "Pvt. medzii";break;
		case  66: self.name = "Pvt. Surviv0r";break;
		case  67: self.name = "Pvt. Ericg08";break;
		case  68: self.name = "Pvt. Soupsake";break;
		case  69: self.name = "Pvt. Klooger";break;
		case  70: self.name = "Pvt. Danza";break;
		case  71: self.name = "Pvt. Bluetarget";break;
		case  72: self.name = "Pvt. mozyakin";break;
		case  73: self.name = "Pvt. Matyop20";break;
		case  74: self.name = "Pvt. Liserd";break;
		case  75: self.name = "Pvt. aut0mat1clol";break;
		case  76: self.name = "Pvt. rythin";break;
		case  77: self.name = "Pvt. Whose";break;
		case  78: self.name = "Pvt. DarkSR";break;
		case  79: self.name = "Pvt. Churp";break;
		case  80: self.name = "Pvt. nehyzo";break;
		case  81: self.name = "Pvt. Aaron";break;
		case  82: self.name = "Pvt. SuperFull";break;
		case  83: self.name = "Pvt. first_try_i_swear";break;
		case  84: self.name = "Pvt. Zayido";break;
		case  85: self.name = "Pvt. iden";break;
		case  86: self.name = "Pvt. Fish";break;
		case  87: self.name = "Pvt. medzii";break;
		case  88: self.name = "Pvt. Surviv0r";break;
		case  89: self.name = "Pvt. Ericg08";break;
		case  90: self.name = "Pvt. Soupsake";break;
		case  91: self.name = "Pvt. Klooger";break;
		case  92: self.name = "Pvt. Danza";break;
		case  93: self.name = "Pvt. Bluetarget";break;
		case  94: self.name = "Pvt. mozyakin";break;
		case  95: self.name = "Pvt. Matyop20";break;
		case  96: self.name = "Pvt. Liserd";break;
		case  97: self.name = "Pvt. aut0mat1clol";break;
		case  98: self.name = "Pvt. rythin";break;
		case  99: self.name = "Pvt. Whose";break;
		case  100: self.name = "Pvt. DarkSR";break;
		case  101: self.name = "Pvt. Churp";break;
		case  102: self.name = "Pvt. nehyzo";break;
		case  103: self.name = "Pvt. Aaron";break;
		case  104: self.name = "Pvt. SuperFull";break;
		case  105: self.name = "Pvt. first_try_i_swear";break;
		case  106: self.name = "Pvt. Zayido";break;
		case  107: self.name = "Pvt. iden";break;
		case  108: self.name = "Pvt. Fish";break;
		case  109: self.name = "Pvt. medzii";break;
		case  110: self.name = "Pvt. Surviv0r";break;
		case  111: self.name = "Pvt. Ericg08";break;
		case  112: self.name = "Pvt. Soupsake";break;
		case  113: self.name = "Pvt. Klooger";break;
		case  114: self.name = "Pvt. Danza";break;
		case  115: self.name = "Pvt. Bluetarget";break;
		case  116: self.name = "Pvt. mozyakin";break;
		case  117: self.name = "Pvt. Matyop20";break;
		case  118: self.name = "Pvt. Liserd";break;
		case  119: self.name = "Pvt. aut0mat1clol";break;
		case  120: self.name = "Pvt. rythin";break;
		case  121: self.name = "Pvt. Whose";break;
		case  122: self.name = "Pvt. DarkSR";break;
		case  123: self.name = "Pvt. Churp";break;
		case  124: self.name = "Pvt. nehyzo";break;
		case  125: self.name = "Pvt. Aaron";break;
		case  126: self.name = "Pvt. SuperFull";break;
		case  127: self.name = "Pvt. first_try_i_swear";break;
		case  128: self.name = "Pvt. Zayido";break;
		case  129: self.name = "Sgt. iden";break;
		case  130: self.name = "Pvt. Fish";break;
		case  131: self.name = "Pvt. medzii";break;
		case  132: self.name = "Pvt. Surviv0r";break;
		case  133: self.name = "Pvt. Ericg08";break;
		case  134: self.name = "Sgt. Soupsake";break;
		case  135: self.name = "Pvt. Klooger";break;
		case  136: self.name = "Pvt. Danza";break;
		case  137: self.name = "Pvt. Bluetarget";break;
		case  138: self.name = "Sgt. mozyakin";break;
		case  139: self.name = "Pvt. Matyop20";break;
		case  140: self.name = "Pvt. Liserd";break;
		case  141: self.name = "Pvt. Makan"; game["britishnames"] = 0;break;
	}
}

get_russian_name()
{
	switch (game["russiannames"])
	{
		case  1: self.name = "Pvt. Ericg08";break;
		case  2: self.name = "Sgt. Soupsake";break;
		case  3: self.name = "Pvt. Klooger";break;
		case  4: self.name = "Pvt. Danza";break;
		case  5: self.name = "Pvt. Bluetarget";break;
		case  6: self.name = "Pvt. mozyakin";break;
		case  7: self.name = "Pvt. Matyop20";break;
		case  8: self.name = "Pvt. Liserd";break;
		case  9: self.name = "Pvt. aut0mat1clol";break;
		case  10: self.name = "Pvt. rythin";break;
		case  11: self.name = "Pvt. Whose";break;
		case  12: self.name = "Pvt. DarkSR";break;
		case  13: self.name = "Pvt. Churp";break;
		case  14: self.name = "Pvt. nehyzo";break;
		case  15: self.name = "Pvt. Aaron";break;
		case  16: self.name = "Pvt. SuperFull";break;
		case  17: self.name = "Pvt. first_try_i_swear";break;
		case  18: self.name = "Pvt. Zayido";break;
		case  19: self.name = "Pvt. iden";break;
		case  20: self.name = "Pvt. Fish";break;
		case  21: self.name = "Pvt. medzii";break;
		case  22: self.name = "Pvt. Surviv0r";break;
		case  23: self.name = "Pvt. Ericg08";break;
		case  24: self.name = "Pvt. Soupsake";break;
		case  25: self.name = "Pvt. Klooger";break;
		case  26: self.name = "Pvt. Danza";break;
		case  27: self.name = "Pvt. Bluetarget";break;
		case  28: self.name = "Pvt. mozyakin";break;
		case  29: self.name = "Pvt. Matyop20";break;
		case  30: self.name = "Pvt. Liserd";break;
		case  31: self.name = "Pvt. aut0mat1clol";break;
		case  32: self.name = "Pvt. rythin";break;
		case  33: self.name = "Pvt. Whose";break;
		case  34: self.name = "Pvt. DarkSR";break;
		case  35: self.name = "Pvt. Churp";break;
		case  36: self.name = "Pvt. nehyzo";break;
		case  37: self.name = "Pvt. Aaron";break;
		case  38: self.name = "Pvt. SuperFull";break;
		case  39: self.name = "Pvt. first_try_i_swear";break;
		case  40: self.name = "Pvt. Zayido";break;
		case  41: self.name = "Pvt. iden";break;
		case  42: self.name = "Pvt. Fish";break;
		case  43: self.name = "Pvt. medzii";break;
		case  44: self.name = "Pvt. Surviv0r";break;
		case  45: self.name = "Pvt. Ericg08";break;
		case  46: self.name = "Pvt. Soupsake";break;
		case  47: self.name = "Pvt. Klooger";break;
		case  48: self.name = "Pvt. Danza";break;
		case  49: self.name = "Pvt. Bluetarget";break;
		case  50: self.name = "Pvt. mozyakin";break;
		case  51: self.name = "Pvt. Matyop20";break;
		case  52: self.name = "Pvt. Liserd";break;
		case  53: self.name = "Pvt. aut0mat1clol";break;
		case  54: self.name = "Pvt. rythin";break;
		case  55: self.name = "Pvt. Whose";break;
		case  56: self.name = "Pvt. DarkSR";break;
		case  57: self.name = "Pvt. Churp";break;
		case  58: self.name = "Pvt. nehyzo";break;
		case  59: self.name = "Pvt. Aaron";break;
		case  60: self.name = "Pvt. SuperFull";break;
		case  61: self.name = "Pvt. first_try_i_swear";break;
		case  62: self.name = "Pvt. Zayido";break;
		case  63: self.name = "Pvt. iden";break;
		case  64: self.name = "Pvt. Fish";break;
		case  65: self.name = "Pvt. medzii";break;
		case  66: self.name = "Pvt. Surviv0r";break;
		case  67: self.name = "Pvt. Ericg08";break;
		case  68: self.name = "Pvt. Soupsake";break;
		case  69: self.name = "Pvt. Klooger";break;
		case  70: self.name = "Pvt. Danza";break;
		case  71: self.name = "Pvt. Bluetarget";break;
		case  72: self.name = "Pvt. mozyakin";break;
		case  73: self.name = "Pvt. Matyop20";break;
		case  74: self.name = "Pvt. Liserd";break;
		case  75: self.name = "Pvt. aut0mat1clol";break;
		case  76: self.name = "Pvt. rythin";break;
		case  77: self.name = "Pvt. Whose";break;
		case  78: self.name = "Pvt. DarkSR";break;
		case  79: self.name = "Pvt. Churp";break;
		case  80: self.name = "Pvt. nehyzo";break;
		case  81: self.name = "Pvt. Aaron";break;
		case  82: self.name = "Pvt. SuperFull";break;
		case  83: self.name = "Pvt. first_try_i_swear";break;
		case  84: self.name = "Pvt. Zayido";break;
		case  85: self.name = "Pvt. iden";break;
		case  86: self.name = "Pvt. Fish";break;
		case  87: self.name = "Pvt. medzii";break;
		case  88: self.name = "Pvt. Surviv0r";break;
		case  89: self.name = "Pvt. Ericg08";break;
		case  90: self.name = "Pvt. Soupsake";break;
		case  91: self.name = "Pvt. Klooger";break;
		case  92: self.name = "Pvt. Danza";break;
		case  93: self.name = "Pvt. Bluetarget";break;
		case  94: self.name = "Pvt. mozyakin";break;
		case  95: self.name = "Pvt. Matyop20";break;
		case  96: self.name = "Pvt. Liserd";break;
		case  97: self.name = "Pvt. aut0mat1clol";break;
		case  98: self.name = "Pvt. rythin";break;
		case  99: self.name = "Pvt. Whose";break;
		case  100: self.name = "Pvt. DarkSR";break;
		case  101: self.name = "Pvt. Churp";break;
		case  102: self.name = "Pvt. nehyzo";break;
		case  103: self.name = "Pvt. Aaron";break;
		case  104: self.name = "Pvt. SuperFull";break;
		case  105: self.name = "Pvt. first_try_i_swear";break;
		case  106: self.name = "Pvt. Zayido";break;
		case  107: self.name = "Pvt. iden";break;
		case  108: self.name = "Pvt. Fish";break;
		case  109: self.name = "Pvt. medzii";break;
		case  110: self.name = "Pvt. Surviv0r";break;
		case  111: self.name = "Pvt. Ericg08";break;
		case  112: self.name = "Pvt. Soupsake";break;
		case  113: self.name = "Pvt. Klooger";break;
		case  114: self.name = "Pvt. Danza";break;
		case  115: self.name = "Pvt. Bluetarget";break;
		case  116: self.name = "Pvt. mozyakin";break;
		case  117: self.name = "Pvt. Matyop20";break;
		case  118: self.name = "Pvt. Liserd";break;
		case  119: self.name = "Pvt. aut0mat1clol";break;
		case  120: self.name = "Pvt. rythin";break;
		case  121: self.name = "Pvt. Whose";break;
		case  122: self.name = "Pvt. DarkSR";break;
		case  123: self.name = "Pvt. Churp";break;
		case  124: self.name = "Pvt. nehyzo";break;
		case  125: self.name = "Pvt. Aaron";break;
		case  126: self.name = "Pvt. SuperFull";break;
		case  127: self.name = "Pvt. first_try_i_swear";break;
		case  128: self.name = "Pvt. Zayido";break;
		case  129: self.name = "Pvt. iden";break;
		case  130: self.name = "Pvt. Fish";break;
		case  131: self.name = "Pvt. medzii";break;
		case  132: self.name = "Pvt. Surviv0r";break;
		case  133: self.name = "Pvt. Ericg08";break;
		case  134: self.name = "Pvt. Soupsake";break;
		case  135: self.name = "Pvt. Klooger";break;
		case  136: self.name = "Pvt. Danza";break;
		case  137: self.name = "Pvt. Bluetarget";break;
		case  138: self.name = "Pvt. mozyakin";break;
		case  139: self.name = "Pvt. Navalniy"; game["russiannames"] = 0;break;
	}
}
