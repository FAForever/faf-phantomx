AIOpts = {
    {
        default = 4,
        label = "<LOC phantomx_0001>P-X: Bonus Multiplier",
        help = "<LOC phantomx_0002>Percentage of the standard bonus that phantoms and paladins will receive.",
        key = 'PhantomBonusMultiplier',
        pref = 'PhantomX_Bonus_Multiplier',
        values = {
            {
                text = "30 percent",
                help = "30 percent",
                key = '30',
            },
            {
                text = "50 percent",
                help = "50 percent",
                key = '50',
            },
            {
                text = "60 percent",
                help = "60 percent",
                key = '60',
            },
            {
                text = "70 percent",
                help = "70 percent",
                key = '70',
            },
            {
                text = "80 percent",
                help = "80 percent",
                key = '80',
            },
            {
                text = "90 percent",
                help = "90 percent",
                key = '90',
            },
            {
                text = "100 percent",
                help = "100 percent",
                key = '100',
            },
            {
                text = "110 percent",
                help = "110 percent",
                key = '110',
            },
            {
                text = "120 percent",
                help = "120 percent",
                key = '120',
            },
            {
                text = "130 percent",
                help = "130 percent",
                key = '130',
            },
            {
                text = "150 percent",
                help = "150 percent",
                key = '150',
            },
            {
                text = "175 percent",
                help = "175 percent",
                key = '175',
            },
            {
                text = "200 percent",
                help = "200 percent",
                key = '200',
            },
            {
                text = "250 percent",
                help = "250 percent",
                key = '250',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0013>P-X: Reveal Players To",
        help = "<LOC phantomx_0014>Determines who will see Phantom-X reveal messages.",
        key = 'PhantomRevealTo',
        pref = 'PhantomX_RevealTo_Config',
        values = {
            {
                text = "<LOC phantomx_0015>Everyone",
                help = "<LOC phantomx_0016>Everyone will see reveal messages.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0017>Phantoms Only",
                help = "<LOC phantomx_0018>Only Phantoms will see reveal messages.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0019>Paladins Only",
                help = "<LOC phantomx_0020>Only Paladins will see reveal messages.",
                key = '2',
            },
            {
                text = "<LOC phantomx_0021>Phantoms and Paladins Only",
                help = "<LOC phantomx_0022>Only Paladins and Phantoms will see reveal messages.",
                key = '3',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0023>P-X: Reveal",
        help = "<LOC phantomx_0024>Determines which types of players will be revealed.",
        key = 'PhantomRevealWho',
        pref = 'PhantomX_RevealWho_Config',
        values = {
            {
                text = "<LOC phantomx_0025>Phantoms",
                help = "<LOC phantomx_0026>Only Phantom players will be revealed.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0027>Paladins",
                help = "<LOC phantomx_0028>Only Paladin players will be revealed.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0029>Phantoms and Paladins",
                help = "<LOC phantomx_0030>Both Phantoms and Paladins will be revealed.",
                key = '2',
            },
        },
    },
    {
        default = 3,
        label = "<LOC phantomx_0031>P-X: Paladin Ratio",
        help = "<LOC phantomx_0032>Determines how many Paladins will be in the game.  (Fractional Paladins are rounded down)",
        key = 'PhantomPaladinCoefficient',
        pref = 'PhantomX_Paladin_Coefficient',
        values = {
            {
                text = "<LOC phantomx_0033>None",
                help = "<LOC phantomx_0034>No Paladins will be chosen.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0035>1:1",
                help = "<LOC phantomx_0036>For every ONE Phantom there will be ONE Paladin.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0037>1:2",
                help = "<LOC phantomx_0038>For every TWO Phantoms there will be ONE Paladin.",
                key = '2',
            },
            {
                text = "<LOC phantomx_0039>1:3",
                help = "<LOC phantomx_0040>For every THREE Phantoms there will be ONE Paladin.",
                key = '3',
            },
            {
                text = "<LOC phantomx_0041>2:3",
                help = "<LOC phantomx_0042>For every THREE Phantoms there will be TWO Paladins.",
                key = '4',
            },
        },
    },
    {
        default = 3,
        label = "<LOC phantomx_0043>P-X: Paladin Bonus",
        help = "<LOC phantomx_0044>Determines what percentage of the Phantom bonus that Paladins will receive.",
        key = 'PhantomPaladinBonus',
        pref = 'PhantomX_Paladin_Bonus',
        values = {
            {
                text = "<LOC phantomx_0045>65 percent",
                help = "<LOC phantomx_0046>65 percent",
                key = '65',
            },
            {
                text = "<LOC phantomx_0047>55 percent",
                help = "<LOC phantomx_0048>55 percent",
                key = '55',
            },
            {
                text = "<LOC phantomx_0049>45 percent",
                help = "<LOC phantomx_0050>45 percent",
                key = '45',
            },
            {
                text = "<LOC phantomx_0051>35 percent",
                help = "<LOC phantomx_0052>35 percent",
                key = '35',
            },
            {
                text = "<LOC phantomx_0053>25 percent",
                help = "<LOC phantomx_0054>25 percent",
                key = '25',
            },
        },
    },
    {
        default = 7,
        label = "<LOC phantomx_0055>P-X: 1st Reveal Time",
        help = "<LOC phantomx_0056>1st Reveal Time (in minutes)",
        key = 'PhantomRevealTime1',
        pref = 'PhantomX_Revealing_Time1',
        values = {
            {
                text = "<LOC phantomx_0057>5",
                help = "<LOC phantomx_0058>5 minutes.",
                key = '5',
            },
            {
                text = "<LOC phantomx_0059>8",
                help = "<LOC phantomx_0060>8 minutes.",
                key = '8',
            },
            {
                text = "<LOC phantomx_0061>10",
                help = "<LOC phantomx_0062>10 minutes.",
                key = '10',
            },
            {
                text = "<LOC phantomx_0063>15",
                help = "<LOC phantomx_0064>15 minutes.",
                key = '15',
            },
            {
                text = "<LOC phantomx_0065>20",
                help = "<LOC phantomx_0066>20 minutes.",
                key = '20',
            },
            {
                text = "<LOC phantomx_0067>25",
                help = "<LOC phantomx_0068>25 minutes.",
                key = '25',
            },
            {
                text = "<LOC phantomx_0069>30",
                help = "<LOC phantomx_0070>30 minutes.",
                key = '30',
            },
            {
                text = "<LOC phantomx_0071>45",
                help = "<LOC phantomx_0072>45 minutes.",
                key = '45',
            },
            {
                text = "<LOC phantomx_0073>60",
                help = "<LOC phantomx_0074>60 minutes.",
                key = '60',
            },
            {
                text = "<LOC phantomx_0075>Never",
                help = "<LOC phantomx_0076>Never reveal.",
                key = '0',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0077>P-X: 2nd Reveal Time",
        help = "<LOC phantomx_0078>2nd Reveal Time (in minutes)",
        key = 'PhantomRevealTime2',
        pref = 'PhantomX_Revealing_Time2',
        values = {
            {
                text = "<LOC phantomx_0079>Same as 1st reveal time",
                help = "<LOC phantomx_0080>Same time as 1st reveal.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0081>3",
                help = "<LOC phantomx_0082>3 minutes.",
                key = '3',
            },
            {
                text = "<LOC phantomx_0083>5",
                help = "<LOC phantomx_0084>5 minutes.",
                key = '5',
            },
            {
                text = "<LOC phantomx_0085>10",
                help = "<LOC phantomx_0086>10 minutes.",
                key = '10',
            },
            {
                text = "<LOC phantomx_0087>15",
                help = "<LOC phantomx_0088>15 minutes.",
                key = '15',
            },
            {
                text = "<LOC phantomx_0089>Never",
                help = "<LOC phantomx_0090>Never reveal.",
                key = '0',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0091>P-X: 3rd Reveal Time",
        help = "<LOC phantomx_0092>3rd Reveal Time (in minutes)",
        key = 'PhantomRevealTime3',
        pref = 'PhantomX_Revealing_Time3',
        values = {
            {
                text = "<LOC phantomx_0093>Same as 2nd reveal time",
                help = "<LOC phantomx_0094>Same time as 2nd reveal.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0095>3",
                help = "<LOC phantomx_0096>3 minutes.",
                key = '3',
            },
            {
                text = "<LOC phantomx_0097>5",
                help = "<LOC phantomx_0098>5 minutes.",
                key = '5',
            },
            {
                text = "<LOC phantomx_0099>10",
                help = "<LOC phantomx_0100>10 minutes.",
                key = '10',
            },
            {
                text = "<LOC phantomx_0101>15",
                help = "<LOC phantomx_0102>15 minutes.",
                key = '15',
            },
            {
                text = "<LOC phantomx_0103>Never",
                help = "<LOC phantomx_0104>Never reveal.",
                key = '0',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0110>P-X: Reveal after death",
        help = "<LOC phantomx_0111>Reveal identity of players after their death",
        key = 'Phantom_DeathReveal',
        pref = 'PhantomX_DeathReveal',
        values = {
            {
                text = "<LOC phantomx_0112>Yes",
                help = "<LOC phantomx_0113>When a player dies, his assigment is revealed to the others.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0114>No",
                help = "<LOC phantomx_0115>After a player dies, no information is given to the other players.",
                key = '0',
            },
        },
    },
    {
        default = 2,
        label = "<LOC phantomx_0200>P-X: Paladin Marks",
        help = "<LOC phantomx_0201>Controls how many Paladin Marks will be given to the Phantoms. ",
        key = 'Phantom_PaladinMarks',
        pref = 'PhantomX_PaladinMarks',
        values = {
            {
                text = "<LOC phantomx_0202>None",
                help = "<LOC phantomx_0203>None.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0204>1 per Paladin",
                help = "<LOC phantomx_0205>1 Per Paladin.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0206>1 per Phantom",
                help = "<LOC phantomx_0207>1 per Phantom.",
                key = '2',
            },
            {
                text = "<LOC phantomx_0208>2 per Phantom",
                help = "<LOC phantomx_0209>2 per Phantom.",
                key = '3',
            },
            {
                text = "<LOC phantomx_0210>One",
                help = "<LOC phantomx_0211>One.",
                key = '4',
            },
            {
                text = "<LOC phantomx_0212>Two",
                help = "<LOC phantomx_0213>Two.",
                key = '5',
            },
            {
                text = "<LOC phantomx_0214>Three",
                help = "<LOC phantomx_0215>Three.",
                key = '6',
            },
            {
                text = "<LOC phantomx_0216>Four",
                help = "<LOC phantomx_0217>Four.",
                key = '7',
            },
        },
    },
    {
        default = 2,
        label = "<LOC phantomx_0250>P-X: Auto Team Balancing",
        help = "<LOC phantomx_0251>Enables volunteering or automatic balancing of assignments",
        key = 'Phantom_AutoBalance',
        pref = 'PhantomX_AutoBalance',
        values = {
            {
                text = "<LOC phantomx_0252>Off",
                help = "<LOC phantomx_0253>Assignments are completely random.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0254>Volunteering",
                help = "<LOC phantomx_0255>Allows players to volunteer to be Phantom.",
                key = '1',
            },
            {
                text = "<LOC phantomx_0256>Autobalancing",
                help = "<LOC phantomx_0257>Attempts to balance the teams.",
                key = '2',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0260>P-X: Meteors",
        help = "<LOC phantomx_0261>Enables meteor showers.",
        key = 'Phantom_Meteor',
        pref = 'PhantomX_Meteor',
        values = {
            {
                text = "<LOC phantomx_0262>Off",
                help = "<LOC phantomx_0263>Meteors will not occur.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0264>On",
                help = "<LOC phantomx_0265>Meteors may occur.",
                key = '1',
            },
        }
    },
    {
        default = 4,
        label = "<LOC phantomx_0270>P-X: Initial Meteor Delay",
        help = "<LOC phantomx_0271>The initial delay before the first meteors can fall.",
        key = 'PhantomMeteorDelayTime',
        pref = 'PhantomX_MeteorDelay_Time',
        values = {
            {
                text = "<LOC phantomx_0272>15",
                help = "<LOC phantomx_0273>15 minutes.",
                key = '15',
            },
            {
                text = "<LOC phantomx_0274>20",
                help = "<LOC phantomx_0275>20 minutes.",
                key = '20',
            },
            {
                text = "<LOC phantomx_0276>25",
                help = "<LOC phantomx_0277>25 minutes.",
                key = '25',
            },
            {
                text = "<LOC phantomx_0278>30",
                help = "<LOC phantomx_0279>30 minutes.",
                key = '30',
            },
            {
                text = "<LOC phantomx_0280>35",
                help = "<LOC phantomx_0281>35 minutes.",
                key = '35',
            },
            {
                text = "<LOC phantomx_0282>40",
                help = "<LOC phantomx_0283>40 minutes.",
                key = '40',
            },
            {
                text = "<LOC phantomx_0284>45",
                help = "<LOC phantomx_0285>45 minutes.",
                key = '45',
            },
            {
                text = "<LOC phantomx_0286>50",
                help = "<LOC phantomx_0287>50 minutes.",
                key = '50',
            },
            {
                text = "<LOC phantomx_0288>60",
                help = "<LOC phantomx_0289>60 minutes.",
                key = '60',
            },
        },
    },
    {
        default = 7,
        label = "<LOC phantomx_0300>P-X: Subsequent Meteor Delay",
        help = "<LOC phantomx_0301>The amount of time that the death of a player will delay the meteors.",
        key = 'PhantomSubseqMeteorDelayTime',
        pref = 'PhantomX_SubseqMeteorDelay_Time',
        values = {
            {
                text = "<LOC phantomx_0302>None",
                help = "<LOC phantomx_0303>None.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0304>3",
                help = "<LOC phantomx_0305>3 minutes.",
                key = '3',
            },
            {
                text = "<LOC phantomx_0306>5",
                help = "<LOC phantomx_0307>5 minutes.",
                key = '5',
            },
            {
                text = "<LOC phantomx_0308>7",
                help = "<LOC phantomx_0309>7 minutes.",
                key = '7',
            },
            {
                text = "<LOC phantomx_0310>8",
                help = "<LOC phantomx_0311>8 minutes.",
                key = '8',
            },
            {
                text = "<LOC phantomx_0312>10",
                help = "<LOC phantomx_0313>10 minutes.",
                key = '10',
            },
            {
                text = "<LOC phantomx_0314>12",
                help = "<LOC phantomx_0315>12 minutes.",
                key = '12',
            },
            {
                text = "<LOC phantomx_0316>15",
                help = "<LOC phantomx_0317>15 minutes.",
                key = '15',
            },
        },
    },
    {
        default = 1,
        label = "<LOC phantomx_0410>P-X: Number of Phantoms",
        help = "<LOC phantomx_0411>Enables the host to set the number of Phantoms, or to allow a vote.",
        key = 'Phantom_PhantNumber',
        pref = 'PhantomX_PhantNumber',
        values = {
            {
                text = "<LOC phantomx_0412>Vote",
                help = "<LOC phantomx_0413>Allow ingame vote.",
                key = '0',
            },
            {
                text = "<LOC phantomx_0414>1",
                help = "<LOC phantomx_0415>1",
                key = '1',
            },
            {
                text = "<LOC phantomx_0416>2",
                help = "<LOC phantomx_0417>2",
                key = '2',
            },
            {
                text = "<LOC phantomx_0418>3",
                help = "<LOC phantomx_0419>3",
                key = '3',
            },
        },
    }
}