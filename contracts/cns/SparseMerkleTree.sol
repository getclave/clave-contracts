// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Blake2S} from "./Blake2S.sol";

// Solidity port of zksync-era's Sparse Merkle Tree implementation
// https://github.com/matter-labs/zksync-era/blob/main/core/lib/merkle_tree/src/hasher/mod.rs
// Type conversion between Rust implementation and Solidity implementation
// H32          : bytes32
// U256         : uint256
// Key          : uint256
// ValueHash    : bytes32

/// @title Sparse Tree Entry
/// @member value The value of the entry
/// @member leafIndex The index of the leaf in the tree
struct TreeEntry {
    uint256 key;
    bytes32 value;
    uint64 leafIndex;
}

uint256 constant KEY_SIZE = 32;
uint256 constant TREE_DEPTH = KEY_SIZE * 8;

contract SparseMerkleTree {
    mapping(uint256 => bytes32) public emptyTreeHashes_;

    constructor() {
        // Empty tree hashes
        // Hardcoded to save gas
        emptyTreeHashes_[ 0 ] = 0x94bb15542026f4f607416f019dffe21bb39bbb32cc92085ab615660a6b5fbef4;
        emptyTreeHashes_[ 1 ] = 0x7952661ab5d63534c5ea72f81887d8dd6bf514b14c8e9fb714b6feb02efb96a0;
        emptyTreeHashes_[ 2 ] = 0x3d75808db532e9685bcc7969ad0f5f0872086b24e02b28cdc7df6e3cc1bd2371;
        emptyTreeHashes_[ 3 ] = 0x29463426092df4c7af14bff4977d825e35d93d5b2c7555997ae0bc5da503b1b3;
        emptyTreeHashes_[ 4 ] = 0x55bdf8e79ad5207ea317d92c4009cea29fe9bb66e0d6cfd5b50cfe202bb7c17b;
        emptyTreeHashes_[ 5 ] = 0x7b269aa0a2836697c2a36aa7e91d61a4e8f3eec4fddda4f0e28f2c00d895f2d9;
        emptyTreeHashes_[ 6 ] = 0xe7d36ccea1ac417362907ff9752ae7beaf3380bc77c554f4c0189915c6e2f156;
        emptyTreeHashes_[ 7 ] = 0xd2d9e3c2060d41b9ef514403cbdf1ed473acf7d6b10518ab0ae119ac3813ad64;
        emptyTreeHashes_[ 8 ] = 0x769e4e5aa4e1968762b761d7213bc1ec97486a83b6d9d10a821dbed37e619ab1;
        emptyTreeHashes_[ 9 ] = 0x01081746734e83cb0afcc9e884dc71e2dc893b74190ae67233b10a333818aaba;
        emptyTreeHashes_[ 10 ] = 0xdcc6d61671642128e20c498ad0ea7e5f02178699a2a3fa4b6d341f78ec1b6f27;
        emptyTreeHashes_[ 11 ] = 0x90aa631a0a952345a6c37faf9f9615bcb79bf3c3e482fb90e7e2943682e95cd6;
        emptyTreeHashes_[ 12 ] = 0x351c803e4a5f9ccdb38e88c63a7f1e6d419d7784da4da58a4ddbba22bb947b88;
        emptyTreeHashes_[ 13 ] = 0x6ff95284d7a2af72fa9bfaf68175bfc726d44d6de42cd55e0956cd3c5a54e789;
        emptyTreeHashes_[ 14 ] = 0x3305aeb5575f473f2bc6561a8a2aa6699de7a9bc0dd1db31843577ede186d025;
        emptyTreeHashes_[ 15 ] = 0xb52a7e7f9609d0f7d208055602c4ccca8436034dcabe8f2dff33148f3beb170e;
        emptyTreeHashes_[ 16 ] = 0x3b21dff05c1fd42478a06e331e850399ab3bcac1ca96f778b11e4f9195c5f3eb;
        emptyTreeHashes_[ 17 ] = 0x5ff91c6907e8ec45ac5dcbc8614d6bd6bc4e87b9612615e4a11492260ace6861;
        emptyTreeHashes_[ 18 ] = 0xf3ca9084d4a47253a68d42ea65f1ff30e14dd9cde00196702f72812934a9c807;
        emptyTreeHashes_[ 19 ] = 0x5371c89c3ba241f45231cbbb2fd462b0db55f8c6385c795a538f704f5b25a8d0;
        emptyTreeHashes_[ 20 ] = 0x070e2ea800ceefac5daa980cb1250c7869deb40128d5d009a7ad762b9598f162;
        emptyTreeHashes_[ 21 ] = 0x5952f729ded9dee4a4ef3c5d9598e2ad950293d8061fa1e53adcf4117c09f9c9;
        emptyTreeHashes_[ 22 ] = 0x15fe4d78d71575df893b49acc33d9113557af357fe3888749b0a210fcf8761ec;
        emptyTreeHashes_[ 23 ] = 0x3d07e28efe5e4e7a7e2f3c557f280f5b9ba24f584fee580357611b9f9365cbe5;
        emptyTreeHashes_[ 24 ] = 0x890017f43434b2a4b995a376e455eb4d6692bc1a9a9bd995f011fdc864dc0ac1;
        emptyTreeHashes_[ 25 ] = 0x2bb086a86d75b83950f62dcbd2be938574b7c7721284009e5a481a0085493d46;
        emptyTreeHashes_[ 26 ] = 0xf486448dfd67d7b5ff80d2ee7df1d05eb6845f4b1bd7e59a2950b048740380ce;
        emptyTreeHashes_[ 27 ] = 0x93d401e5c105a345c1090360796ffedc81377468ded6e3b8c5d0f6e0bc9bd232;
        emptyTreeHashes_[ 28 ] = 0xbd59a52d343e78ea0917b3666f048c251c567d4757a7ed6920aee1a0494f34d4;
        emptyTreeHashes_[ 29 ] = 0xb410a350abfe2bff5cfe602dfd4f62f5c178f6fd7905a48a5d57016e748464d2;
        emptyTreeHashes_[ 30 ] = 0x9bf2f7c5ff739af9dcb04ff3f4ddb2daaa2ded109fc37224abbf097e79db883a;
        emptyTreeHashes_[ 31 ] = 0x2b2b011623060371c1287ac5d0b972ea0acc3e0625479c62f58b1dae9a4e4f0e;
        emptyTreeHashes_[ 32 ] = 0x16fddc72c53f0168b0bc75315f71955b5a616dd9e976dc1d70857ef851bcf87f;
        emptyTreeHashes_[ 33 ] = 0x4f6ddfa4e7a78272d476c78a8e20d75e67b34817fea9699e157a4327999aeabd;
        emptyTreeHashes_[ 34 ] = 0x8a48da19397975fa48f382dadf0db0543f8a1429890791f8edf9d85701cc090c;
        emptyTreeHashes_[ 35 ] = 0xefcc3ad578210006391a5bdcc14416df8c665ef18a34a6fbee768c81366170e2;
        emptyTreeHashes_[ 36 ] = 0xdfc2706b3b0046eb44b04dd01f9c68396c69566bd878ef15fa1602af6d0c3271;
        emptyTreeHashes_[ 37 ] = 0xe575e6bcc863d5a637946f9499aa671c1a026553ff44eaeb6bce593ad7be9509;
        emptyTreeHashes_[ 38 ] = 0xfb885db102e10d3c885c8b9ec215c1d3f54414aba4a3725387bd27ca4a3b5788;
        emptyTreeHashes_[ 39 ] = 0x307bad1feb84aacf221f357bd44fd8424dcd9ad91be7b7c75c2c2688dd09a2dc;
        emptyTreeHashes_[ 40 ] = 0x26faa4b413c6184fe577e5c181cc658ab8a6b794497220eb9e870a53cf9c8616;
        emptyTreeHashes_[ 41 ] = 0x97dac09f6227af3c8fa4b84c8ac7f4ca78d0e5a5acd81fa5419263a0b770e7b0;
        emptyTreeHashes_[ 42 ] = 0xed615f12b68ea966366a3d9cfaae12560ba721dde64ef42db4e3c28eebe9e7dc;
        emptyTreeHashes_[ 43 ] = 0x46fb536a51cb284ce7220e10c61fb7a9581dce2cf33678082b7ccffeb078e86f;
        emptyTreeHashes_[ 44 ] = 0x65be4a061edada9664ed7eabcbb82306dd1dc4d257215dee2cff096683d7ee31;
        emptyTreeHashes_[ 45 ] = 0x553c120a031f25e775c510e9204b85b2d744ac64f6890c0e372f98ae68111b5d;
        emptyTreeHashes_[ 46 ] = 0x913523e30ee062c2f014307dbb77442447cdc6384556ce5385ce30ae99fe3f1d;
        emptyTreeHashes_[ 47 ] = 0x5968fcade071909e6b28fe49443318733f443cfc997908d18cad658f51d563aa;
        emptyTreeHashes_[ 48 ] = 0x0063d4b6834eb27132e3db7dbca5271a1c1be3ec0278e1476238f9567bd2c923;
        emptyTreeHashes_[ 49 ] = 0x27bff7a116ef02256b937f0d6e189954fcda55ebdbd0311add6710f24587acef;
        emptyTreeHashes_[ 50 ] = 0x3d030a55a63d3686af9d9206fc11e989bb754d091e31def3b766a99926d7cc0f;
        emptyTreeHashes_[ 51 ] = 0xbcac725d366e063158fec8b765ef34dbfe4661a16a024d068b7e8b8c69c969e2;
        emptyTreeHashes_[ 52 ] = 0x667b4cc062dbb7ea73ce2d3765852659ba0d9e50feae1c8f0e03d90c63343fcc;
        emptyTreeHashes_[ 53 ] = 0x7d7b6e62b251d75925ae34a3064b6619b1e92bc0d1b08a578bbb69841f101bd0;
        emptyTreeHashes_[ 54 ] = 0x62402e1ce7d21d56d7ab8acca37aef7210e13b48f7ee4e418d4b738a3ea7ed22;
        emptyTreeHashes_[ 55 ] = 0x83ff1784605dce2361c0feb2bd4e19825cf31f381832b10d19aff4b7a505a137;
        emptyTreeHashes_[ 56 ] = 0xa1791b1f9a05aebc8712ca3318786e23245322f1a7a9c6a8a19c456b0d5065d6;
        emptyTreeHashes_[ 57 ] = 0x751b8b069eaa1f8fec4ff9e0f88b85de603f9412e043446d9a36cf5bfccfa386;
        emptyTreeHashes_[ 58 ] = 0x8a06e0ee48a723bcc78357aeb142fbd67253990fff5285233dfa1a9596a2a1af;
        emptyTreeHashes_[ 59 ] = 0x52f8a45813f1cbfa0f1d666813acc882dfa8bdd659ed3921504d3832c55235c2;
        emptyTreeHashes_[ 60 ] = 0xf377ceca19baadcbb37e12850efab50729c0a4398aaa904c36606f8de7475ab6;
        emptyTreeHashes_[ 61 ] = 0x511e6d6a77e31301e6612b256f21e2e6260d825a75795a537b71500966d929db;
        emptyTreeHashes_[ 62 ] = 0xbe3ffa66a40a99ac70a97f9548e8dd728d30e7c8dff5fc914408324343e0f08d;
        emptyTreeHashes_[ 63 ] = 0x607319f7dd524f9f0a2be78b462620c8760962b79f957e2218ad41725ee89583;
        emptyTreeHashes_[ 64 ] = 0x58fda4e0001cbc69d76f7607af089bef317f4bfa318f283bb11e9b345e1bdfc9;
        emptyTreeHashes_[ 65 ] = 0x6c98a54803f13fd7476030a83df64f2c1d4bf7b755219ffb738b58cce3061bda;
        emptyTreeHashes_[ 66 ] = 0x403c1833bcfc771436f27308f2513b2c06c42209f263b5c1c2cb25e050173aea;
        emptyTreeHashes_[ 67 ] = 0x5fa220b7bb9dfc2d0fa7f744c2b4b71e8f1133350ddfc2c7fa0c39a2534caba4;
        emptyTreeHashes_[ 68 ] = 0xac896816663c28007c11f8dec98e39861f9cfd40061292e311ed89aae4426db0;
        emptyTreeHashes_[ 69 ] = 0xc76d7cdea8ad8572209136bc24ee3f2b3c704e179faefc961e2a2c66b0976771;
        emptyTreeHashes_[ 70 ] = 0x5782ce904f9bbf33717f9911a788f29dd82643c16e92cd1b301112b9d2d8c341;
        emptyTreeHashes_[ 71 ] = 0x849a22938ab76a28353d6ff6682777b19b345f48f292868015f4484f1ece8bfc;
        emptyTreeHashes_[ 72 ] = 0xea4416c46e8e978e4d24bf68f1bbc36a7c6a24e937d67128061ecdd0efc01320;
        emptyTreeHashes_[ 73 ] = 0xabda90ce54b015a1919b04fc7385313a93d650e01abc97d4ea2939a4a8abf357;
        emptyTreeHashes_[ 74 ] = 0x458b081dc3dcffd435d8880848adad8f0f2ac329ad64215763e0a3086228db5a;
        emptyTreeHashes_[ 75 ] = 0x7b45ad842b671d75792baf30a75e45bc97f9b6dc37f86d1e6b30c0902d1bd24e;
        emptyTreeHashes_[ 76 ] = 0xfe02e60c0135882add8584bef8b28564cceb75a3c7602dd00fcd95d73e26d487;
        emptyTreeHashes_[ 77 ] = 0x2e40946b9ba6a5cdbeb090bbdd67917de698da5551ccf5d9fbe3a17abe14368b;
        emptyTreeHashes_[ 78 ] = 0xba45e0f142fa48a7ab346c2dc38450a03b0e8e606f1032218b368e4466c6cda7;
        emptyTreeHashes_[ 79 ] = 0xb2b4f4707aa7b1518159e7928ae8ee061e200a31eda791a6dedce41745a4ac78;
        emptyTreeHashes_[ 80 ] = 0x94ae11cc3b8f36815124a4b0a5e7334fbcb9fce317bb1390e421334bd6cf6fd9;
        emptyTreeHashes_[ 81 ] = 0x9ebbff604be1d295ff131fc099d9dcc073d050fa52c8d5e48f76df65d2645281;
        emptyTreeHashes_[ 82 ] = 0x5e4a188a19954a007601c5864cba12194e52e1e6fb099068d4ef70e94c5d34a6;
        emptyTreeHashes_[ 83 ] = 0xbc3f4808d7fbfcc52be674774332cddcbfc478d038fecc181566a051e636e9a0;
        emptyTreeHashes_[ 84 ] = 0x5ae26f7f062461e4ad9150ba7090b06ccf15e88f780d880900909c0e6651ef0c;
        emptyTreeHashes_[ 85 ] = 0x1ae48f07b56715ca2f319da11bb21e386a58350a725db6ff1a6a0632246130ae;
        emptyTreeHashes_[ 86 ] = 0xa32add3446a75a8aaa1407817fc03fce86dcbb2488ccc52fd1187be7235e480c;
        emptyTreeHashes_[ 87 ] = 0x66bda0fdd030f223d61b3fe7b17edafcfb0a4b866aa65272eedc3939dfbc4df2;
        emptyTreeHashes_[ 88 ] = 0xd13c036805f47f6d024e6864983ea60b99ad6a06ea66b347d87d164c3099456b;
        emptyTreeHashes_[ 89 ] = 0xe87e8e29e310a425b5ee5d75bd0e85fae12987660bbcdb36420831aa877a0240;
        emptyTreeHashes_[ 90 ] = 0x369913efa08788a5b6e658878ba7f4c435f2d74a24d4575616d8f398c4279d30;
        emptyTreeHashes_[ 91 ] = 0xc1fc63a024a455c3b92631e1e2be341a1671c1c69f57f746397002f8e8fd7844;
        emptyTreeHashes_[ 92 ] = 0x6c245e27871a203f13f4dfa0965350aaa954ad29085223d481f077d0b54cfb25;
        emptyTreeHashes_[ 93 ] = 0xb5a4e34bdf9f72712ca3f129a728dd026268647f96806263768d9c327fde0edf;
        emptyTreeHashes_[ 94 ] = 0x1155662f3ba0306ca84578c4d5f0e033e2f32dec05fdf3260dcc5392feee0aef;
        emptyTreeHashes_[ 95 ] = 0x5cee98caad5c7c7b2944d8e6eb191d5be6e58ea21484ec484dd9e60322e60e19;
        emptyTreeHashes_[ 96 ] = 0x727ba92c1966ab8d657ef2cdc02ae30e95fccc8877d529b49c308de9d2f2da62;
        emptyTreeHashes_[ 97 ] = 0x88b03a75bde9d0116ef5451bfc3a39695856b188ddfefa0e4eafb3ee554a269b;
        emptyTreeHashes_[ 98 ] = 0x37e159bb27c8ba678da8a85626c732e666c067e515149afd90954b600a5cac4f;
        emptyTreeHashes_[ 99 ] = 0x3046f54f449775c20052e9a9ac10c9ceb6913a0e19a887d02c423bf30a1ade45;
        emptyTreeHashes_[ 100 ] = 0x2e08022b2967de107f9a1bc230904ced7ab67554257bce6e9ea479a99b0c4e95;
        emptyTreeHashes_[ 101 ] = 0xdb4883208ab757afe85f3fb2297cb7305c3d01bcaaccf8d956b8139411244c18;
        emptyTreeHashes_[ 102 ] = 0x2a39fae44e6a832a8fc09ce44c99a6fbcc4189e018e54771d3b230142a915268;
        emptyTreeHashes_[ 103 ] = 0x662ead16353a65f7cafb0363528e7f9776d83628a23ad1559ea8cbeeffee562e;
        emptyTreeHashes_[ 104 ] = 0x34166debf87062b5154a9ec9332f52062c2adf3864d482134c8c6a9818170f7c;
        emptyTreeHashes_[ 105 ] = 0xe44b29e69468bc5f7589c2c2ecf56db5aaefaa38ade46a180c5b99a0515fd86c;
        emptyTreeHashes_[ 106 ] = 0x22385e3ecaf622f2f812d9f096ad752185ee8b8c54f25b4263fa783688817592;
        emptyTreeHashes_[ 107 ] = 0xec5ee649cb1f99c3cbd2b11ad341b9c0ebb41f26c9046e9fbfc53e890500d54d;
        emptyTreeHashes_[ 108 ] = 0x37a16cf3dd5c6e3d89c541c617a0d0f77d687ccfab1b76b5104ed8f531242b15;
        emptyTreeHashes_[ 109 ] = 0xd7f3ad3ff135f3d8411498a0b3755e03af7b60469b76b35eec9b480cf0127c3e;
        emptyTreeHashes_[ 110 ] = 0x10d6d96785d486e4d96761778700177536372e04a32e1b707eb3e644698c5849;
        emptyTreeHashes_[ 111 ] = 0xf80ea428d7e07005a3f297625ae8a14653f9afd1be5d7275400cfa8d1b67abf5;
        emptyTreeHashes_[ 112 ] = 0xa9383b95636efd30b1f6ff709eea46efe10a76d3e3b3ea5dcc9aced69fb67827;
        emptyTreeHashes_[ 113 ] = 0x828d31fab8708ebe604d60aaad6e8befbf8f7233fabe2af7001ba80851474486;
        emptyTreeHashes_[ 114 ] = 0xfae85a1cdd55662e0cf9c12e19c874b932e1dbd4e334e8b98ca44a7920a3ba29;
        emptyTreeHashes_[ 115 ] = 0xc3bf7e2d44787cb559519141a4a1df6000be4018856188bd606ab5b12e4b0c18;
        emptyTreeHashes_[ 116 ] = 0xe4919631d0f624b9cd70f43f201eb6c7a8a3629e03df57265bae1f7cc07abd38;
        emptyTreeHashes_[ 117 ] = 0xb6af8e47dcff8068508cba35fd2a67be41537c4b800a438ebc7c329dd44b7d7d;
        emptyTreeHashes_[ 118 ] = 0x563627ce3e3d74e5d12beca851b89a6a57b488c89fdd5b6c803de3d07256c091;
        emptyTreeHashes_[ 119 ] = 0x05bb69c64a48298baff04b70f19898ead2a9a22d08d8a37790b0b3e30e726319;
        emptyTreeHashes_[ 120 ] = 0x36d70ddbce6a61dedfe197d77c291be0a8cdfbb849943d6fe9e0187fbca0baeb;
        emptyTreeHashes_[ 121 ] = 0xe17b321345876464ca81d19236912ab467e0bc6671391bc88323fb3edf5ea1bd;
        emptyTreeHashes_[ 122 ] = 0x141d36918359d4a3b785e241ef98807dbd984e00dad24f2781dc87a79ae0171b;
        emptyTreeHashes_[ 123 ] = 0xad842069a2226ac8a4af5fe449bbda223449199d979441a0353ae4a04feb3d52;
        emptyTreeHashes_[ 124 ] = 0x73cc944dbb843eee36b0cbdb25b268b9940390112d6c5867b12a14fb55cfd38b;
        emptyTreeHashes_[ 125 ] = 0xdb20ab3ad2ae2245b1859768404c69140969271808da30e399510d30a68209a6;
        emptyTreeHashes_[ 126 ] = 0x898e46d51e2cd328c3fdd68ab59b3d1251496c151596973056245caf2394a2dc;
        emptyTreeHashes_[ 127 ] = 0xc2b50393323af4cc3fdba0be867f76d500e77eccd44c9af7d50fd53a51256f37;
        emptyTreeHashes_[ 128 ] = 0x44feae9f59306da5f3415743c1fa74177ec087a83bf7d9e27e357a5c5101d800;
        emptyTreeHashes_[ 129 ] = 0x99c73ac1b891357d930d40541aad7c32ee01e7506c25a659a2f6eb1091b15393;
        emptyTreeHashes_[ 130 ] = 0xa3ab34f6a0e72911c75d2ebedc0a2110a0f64bdd986c66a5e1ef974fcdec7b22;
        emptyTreeHashes_[ 131 ] = 0x846997cb70d3df079d34c15a0328c07ee0c22cf575c027c240064cefa10aaf4b;
        emptyTreeHashes_[ 132 ] = 0xa766e76df91de995c6d112d65fff3685e863e45786da9f4c5808e1eb6dc2ffc8;
        emptyTreeHashes_[ 133 ] = 0xdbfaad393b49f469cdf4e94fa08dc39ce1b6500ef215078237d303e6cb294b59;
        emptyTreeHashes_[ 134 ] = 0xc62306bac17e5638da4c463336929f6631d641a077f2f169ae10587974fd0b90;
        emptyTreeHashes_[ 135 ] = 0x879df3f243797ef924d4e4430443d1389256a085726fd63ffb2118ab78da8a96;
        emptyTreeHashes_[ 136 ] = 0x95afd8d6299c48500ecd68787b6482cede1d86db5062be284476c962f2432cb1;
        emptyTreeHashes_[ 137 ] = 0x152e243edb060a45e36db5f9a7b441a0816e8cd5dedbdc33eed6a0e7ffade54e;
        emptyTreeHashes_[ 138 ] = 0x652dd32861ca3df609f85071ad2cb2a1e29c8771cd2424df015f3ac257305783;
        emptyTreeHashes_[ 139 ] = 0xd9d166fa543545352f634e4b64f3f406390c45db8b71cebc9b34378eb8447c13;
        emptyTreeHashes_[ 140 ] = 0x4f7e78304c85155bd0d0286705e9f4d9ab0dbba6be657150bace0a7b85ca8d66;
        emptyTreeHashes_[ 141 ] = 0xb56571368d19519fb46dd228bf726a46d80d554bf21077c0c247017be1172a5f;
        emptyTreeHashes_[ 142 ] = 0x6f17b1fae5d675ed9bf1bc56cc1df69e69af7afaad7af59e35f20c78e2ea9d7c;
        emptyTreeHashes_[ 143 ] = 0x62c531c949c6540629a0c8dfc7e3e8c101d703ba4245ee0c7bbe4dd8ea8a3c21;
        emptyTreeHashes_[ 144 ] = 0x1fe1091af9dc87a072c1c6022e3d81b7837d91e3cfbb9325bed1a6a0d47427af;
        emptyTreeHashes_[ 145 ] = 0x55a4f533d6dac9a11cd491c152c384babde2a8a9b26a33d6a986bf46643eb3cb;
        emptyTreeHashes_[ 146 ] = 0x12485a190b3d5d04f7f1fdafa1e93a215b5d58e248ce50c7bb99f78630ac5e1f;
        emptyTreeHashes_[ 147 ] = 0x955660ba9db3d36aba12c604c70beca63a40c71be7c136ccaec702740181c4df;
        emptyTreeHashes_[ 148 ] = 0xa34f1f178ecf9f00bcac16498fa5afadba54394e7d034b0a754e8cbf23686bce;
        emptyTreeHashes_[ 149 ] = 0xcc53b87b50a5e102d2e1c366040f15ae6d9fb918bfae1fe9b93b1ffba789f4d1;
        emptyTreeHashes_[ 150 ] = 0x8828f94f4f8c8f04e0a49df2d0f65f18adec69084de7c074dfcfac9a181916fe;
        emptyTreeHashes_[ 151 ] = 0x2a29dfb789019e2a7cb8954624561e28db729fd7f96f1a9e3d80cddb9a3419b9;
        emptyTreeHashes_[ 152 ] = 0x58352c98ae7f81539d08c0faa55688dd2c4bf1dbbd4c1f9bf097577136853b0e;
        emptyTreeHashes_[ 153 ] = 0x8a974664ccdf5bf982e35fa4a807eb66150c171274d54f47b85ac4dc9549d225;
        emptyTreeHashes_[ 154 ] = 0x3864bb3bf364ad835f35774bcbff61fb1a2c414bc98af4a624fc4173b8828f82;
        emptyTreeHashes_[ 155 ] = 0xb2c80f33312f266cbf386bfdf82a74e71c8e4b50e30828a59df7ca1c6c28ac5b;
        emptyTreeHashes_[ 156 ] = 0x050f9c2e1144bd28e4f09c8de6a5872f625aeb41c12faf0dabf09265018dc4ad;
        emptyTreeHashes_[ 157 ] = 0xc3d65393ed3a849346ea8b0e24c60f2cea676bf4735ffaa1363f97c28dc6e50e;
        emptyTreeHashes_[ 158 ] = 0x5b447234b328dcad7e1ab69312579b43251820db248947f4b99643368ec37338;
        emptyTreeHashes_[ 159 ] = 0x651b4804d24b95de3b375dc8bb20e90a9f7eff785da8d84ab79cf04342f45708;
        emptyTreeHashes_[ 160 ] = 0xadc43c534046af6c70f1c7c366e7bde9cf417fd62516cf274d4accf75273d1d6;
        emptyTreeHashes_[ 161 ] = 0xf279cfb23404b9050675c8e0c8050d98c03f47260d9c37e75b4ad96fca8fbdd4;
        emptyTreeHashes_[ 162 ] = 0xf07f2da83753db9fd6fa4514ebe43e82a7b6a3fe4955f51ac170bb8108a7434a;
        emptyTreeHashes_[ 163 ] = 0xe643d4e12c499e47021c30ee2940689435768e9c2f62c0cec60ca4f83e9892c0;
        emptyTreeHashes_[ 164 ] = 0x8b10fdccf3a4ae8c8f955e4bb6e96bf7e83aa1747faf0f7d1b3f15e3ca299f2b;
        emptyTreeHashes_[ 165 ] = 0x05f218091c86c01ac8550c1aedd16b7d93221a3cfa8e9f14a5bbe9938d7543ff;
        emptyTreeHashes_[ 166 ] = 0x692f3b9ecf7682df49f47a5e4ab30e7e7a623650bbd5cf3fe515b380d606ab01;
        emptyTreeHashes_[ 167 ] = 0xf3c455276c2bb31e2024e0df0a2895d286918659a28136d9d52ed47254b9531c;
        emptyTreeHashes_[ 168 ] = 0xddbbeb7da840fb7cce492c77c234471b2c4756cfced86527ddbadb35ee378353;
        emptyTreeHashes_[ 169 ] = 0x90156419b5feceafd068406226dd91afb8cf2eb435f1a6a18e54c57efad9b8de;
        emptyTreeHashes_[ 170 ] = 0x9cd4125af6be61fe5e2aa36e0515879d39cb9cb73c0b40fcf8502775136ca05d;
        emptyTreeHashes_[ 171 ] = 0x0a253041b99ce28b86dde27b93187c6cdae856956bcf108f6f8ca7de76202d72;
        emptyTreeHashes_[ 172 ] = 0x15dd747feda5303671a00ac081129033adbde666436e35250b05812ce7225bca;
        emptyTreeHashes_[ 173 ] = 0xc02ae0a01e3069647714226a4d6ffe0f416698bcc4fd4c3f0c1bc0391519d26e;
        emptyTreeHashes_[ 174 ] = 0xe12befa530480449b164522e1f449e36a845132d2fae947fad6c3cd798b93c3b;
        emptyTreeHashes_[ 175 ] = 0xd9ad7840a0b04c36f0639f93d97666c08df9713be41e315bd6341eff2460dc5c;
        emptyTreeHashes_[ 176 ] = 0xeadaa256f8de320fa2ec43bd99c410d190733b30297b50e36b5080345bf288d2;
        emptyTreeHashes_[ 177 ] = 0x2888a5034a5782cb1de792c5cab2ea8c95ec393694895929add4aa2d55d25d61;
        emptyTreeHashes_[ 178 ] = 0x95085d567f1c0ab86f7d146d697f390d4f77610177e8a17e016a0efa4da6d1be;
        emptyTreeHashes_[ 179 ] = 0x0c6a2909792a08f0c17d3017d375ad664e2567bdf7935f7dfa03b0aee0dda7d5;
        emptyTreeHashes_[ 180 ] = 0x1a9b629afbf4b183e5011786029348abb367ab062456acec116cd6ff210df9ed;
        emptyTreeHashes_[ 181 ] = 0x12ae4581b7af256b70c040b4329b12214b114e5c7b5c00d48c5e240c0549e7ac;
        emptyTreeHashes_[ 182 ] = 0xeb867ea531c8fa0ee36cad6fff1bed461950b5d6ebed07c5adab76929e591299;
        emptyTreeHashes_[ 183 ] = 0x8212e0d37184b7fd6e4369a638f99e30af798a9c5d4ccfbde51885e042473b1f;
        emptyTreeHashes_[ 184 ] = 0x7ef9e666413b6e346ac0a5e9d80ef1612d6edd04ef14629564faab10b296a72d;
        emptyTreeHashes_[ 185 ] = 0x487d10feda54c78ef4c60f09d1ce4460b8557e2cc86bf1a9d12b63425d98a73f;
        emptyTreeHashes_[ 186 ] = 0xc268b135329d80e827c3988d766e327a14ce181ac633a3622ce86eb9c313c10b;
        emptyTreeHashes_[ 187 ] = 0xcc026cc79a65875f9074a4449426d47ca79a6fdc4697fa9617af1904402de30c;
        emptyTreeHashes_[ 188 ] = 0x919a6ed5d2eb768d312b3cf64f6e1c91235b48c329f41fc91f32fa03d9bda552;
        emptyTreeHashes_[ 189 ] = 0xed06115c713cd6fe2ad4cb59701453c53dcb6c8841ab725230bbe1cb55d5ffc2;
        emptyTreeHashes_[ 190 ] = 0xefe11a46f29433a69259289b36663e9a2ac2dccfd959339c39894331f2fe953b;
        emptyTreeHashes_[ 191 ] = 0x8f42939d0de45b67b6912e60a2f1ec7eb2b5ee06ee7df22bd74f149b8573daf6;
        emptyTreeHashes_[ 192 ] = 0xefcce2f150331e37a9e8362d2969c0bff63633b0ef9fdbbf466404db2749e3c6;
        emptyTreeHashes_[ 193 ] = 0xc136b465b68f78a83db6d05f639bb37a45fff5567d91b954ec6d0be266c77d49;
        emptyTreeHashes_[ 194 ] = 0x50467238efe4b40ba2245059360401100f78a799696815c7144aa01defaa5ba4;
        emptyTreeHashes_[ 195 ] = 0x3a07dfbba08ddb467e7f55361ed63fd02daa847db2596f199338b9b3223e45e2;
        emptyTreeHashes_[ 196 ] = 0x6f849eb126cb1dc87eb588c34fd482eb8e861395c992b0730b88df792f261b8a;
        emptyTreeHashes_[ 197 ] = 0xb4a82f98b96b64aa4fbdf9ab26db424f9facda8fc11bbbc6195028feb2556743;
        emptyTreeHashes_[ 198 ] = 0x98c3f4dafca9946ddd7fdaf52888222f3455f28275d9073047e94e114e78e181;
        emptyTreeHashes_[ 199 ] = 0x16df93ccda38738f5ad8ca5b3de0e98f62afe088c8519f3ed663dacfef1e977a;
        emptyTreeHashes_[ 200 ] = 0x19ade9290e6230aa34f05bd1dd2f2d864c7837dc4f67efba7766ac3a688fe662;
        emptyTreeHashes_[ 201 ] = 0x752294bae6c061e5e009bd65681ac5df76be0d8bfd2fafebb53ccdb0d7646a76;
        emptyTreeHashes_[ 202 ] = 0xf220f3915c29bca7ed5002a795815a7f835823d4a70cc153d7f267e0817cd118;
        emptyTreeHashes_[ 203 ] = 0x1179d0892a2e5d43761d97552edde68aca58963e040a24a0d3b0b2dd6cef47a8;
        emptyTreeHashes_[ 204 ] = 0xb80310dce1d65c454cf6c407b51a1b510b36cacc81f586e2ba6d33bd835924e3;
        emptyTreeHashes_[ 205 ] = 0x62b70602c5e0639528a780b9536bd9ac7544a040347a9055ba6c94eb4a3eea51;
        emptyTreeHashes_[ 206 ] = 0xfd59914727fecbde053b642e5578d0d2431c8bb45b428b64765b270406444e3b;
        emptyTreeHashes_[ 207 ] = 0x17fab55e7e82131b83c78f3a77294898bf4d5ef0613097bab861306804dd4240;
        emptyTreeHashes_[ 208 ] = 0xb82cf21c37c587cd04246c2fe8e5548efd00c17060ee2871429d81f7755ef110;
        emptyTreeHashes_[ 209 ] = 0x988b3477e88f23909b5c0a09f8c689fedd59eecb868a294a0ca351823146f981;
        emptyTreeHashes_[ 210 ] = 0x9e11ffef69f46a2415e5d3540c61da673488cc730217708e79e8a56fb060e847;
        emptyTreeHashes_[ 211 ] = 0x629128f7e24d93e8c4aace58b4673d9e35f9dec26d0663d16eb823bd17fca7c2;
        emptyTreeHashes_[ 212 ] = 0x2d629cab81e33db7e048dab910c79d72acfb973b17625b96972ce5bc17b2ac4f;
        emptyTreeHashes_[ 213 ] = 0x60f6fc5b612b2fdc3740a4c9ee809777f6bd5bf71eaec7040036db21daa4586d;
        emptyTreeHashes_[ 214 ] = 0xa80e562644ef7524526554f216cd5fdf9add0d598382facca41c56ba4b1f37e9;
        emptyTreeHashes_[ 215 ] = 0x307294a46497c93728359e895e68d115bdfbafdef5ee8061b8d8166bf2af8521;
        emptyTreeHashes_[ 216 ] = 0x698f011e9b2e4b90b091a7caba3ca35dd682745391f606e6cc687e0f2daa22bc;
        emptyTreeHashes_[ 217 ] = 0x7f4ebae60350d098f834b671918984c9ad5c05d893f7de4793dd068006f196f0;
        emptyTreeHashes_[ 218 ] = 0x6bf6efe7ecdd3d42312df60bb708720765d819e58f3f59fb50946ffb6fc4f81b;
        emptyTreeHashes_[ 219 ] = 0xb43fcdf724e2d2c62db5e49a88a2af94067ffe8984e37681e664ff78cccde4c0;
        emptyTreeHashes_[ 220 ] = 0xa0e322a1bb63c7f43ca00136a60f6352a5457c31a66aea20b33754562e4bdd76;
        emptyTreeHashes_[ 221 ] = 0x1cc273760d600d6d76604b2ddb5d9f6b7bdd32aeb231c7507521d85cd4bd3035;
        emptyTreeHashes_[ 222 ] = 0xcf3072ad71bea0ff55900df08eb223f660a32e2d64e692c1bb6a57644e697d7b;
        emptyTreeHashes_[ 223 ] = 0x1e2029a25ae03038be0fa85287b18ecbc3fcd6144f78ac67996dae2f16d79e6f;
        emptyTreeHashes_[ 224 ] = 0xc806d764e94bfbad0ce94201376899ee64ac0e37f10143a20208b6225e120e75;
        emptyTreeHashes_[ 225 ] = 0xc8d3c5ea0e45b01eb88800b3d186e4f054ed967e3aaec0721458a2c8d67f716e;
        emptyTreeHashes_[ 226 ] = 0xb66f590de840a0b68b431ba1c4c7d493d9bb7996b8f92817627ae91ff85f94fa;
        emptyTreeHashes_[ 227 ] = 0x69eecc684348c834fdf786a23a2c0d7bf2b6701c951fab54aaba1b4ae870b642;
        emptyTreeHashes_[ 228 ] = 0xa6ae29b62375dbf000c8ae1048e0fcab7b56e03949201682553ed0a548278bf9;
        emptyTreeHashes_[ 229 ] = 0x0a39e3389d2437d160f3d95cdf30f61c1afd52a2f82cafd2ac32a6b6ea823e9b;
        emptyTreeHashes_[ 230 ] = 0x154239aae4f546bc027500eae27c714ce01ad0200462bf47c6807564e0e4a468;
        emptyTreeHashes_[ 231 ] = 0xf09bbb2d19218100f0dd9b29f6b7ac6abd09ba145a1e9a6df989b1e39f097c22;
        emptyTreeHashes_[ 232 ] = 0xe7a7c1f87beafe1895c2bcd421fc77d734f76799d2c0d9c23bcf71b9fffc2699;
        emptyTreeHashes_[ 233 ] = 0xbb4e9c282c174e3d438c63ca40ecba99b6e4cb0fc55c6c8cc940fd3f5c6528c9;
        emptyTreeHashes_[ 234 ] = 0xed2d5bbf62e6bcdc2e1ee1ba63cf2781eb7ee668fb9eb2fd9ee717d0ce1a6f83;
        emptyTreeHashes_[ 235 ] = 0x6cc625d132fbfa408f6bc106176db4ec6fec3b8fa55565d0615b0aad23193304;
        emptyTreeHashes_[ 236 ] = 0x6697e0fb9053689008e7a063e84ad084bf2ee29fa8c5bc60857ff40c6dd96fe6;
        emptyTreeHashes_[ 237 ] = 0x1e72d341b4f5f75fdb9e881516d6b31725a066a5ed7538a05d9093041e8879e7;
        emptyTreeHashes_[ 238 ] = 0xc6c7af64486c17903cf4e142f46b27aca0a3876476d45ca0f8a4cc91301edec4;
        emptyTreeHashes_[ 239 ] = 0x1ade2393a6111780d70e239968f7d4f48828c7d0d62ad9d58aca5cc5fd6f2cfd;
        emptyTreeHashes_[ 240 ] = 0xa54c07a3fe146ef5bcca630eeedf5f6b3cd9b7d9e90f2b342daf56d6db6df70e;
        emptyTreeHashes_[ 241 ] = 0x9c81aa286afca7471f51b6a9d1a04236ef9def691959d47c2b857fb27d358968;
        emptyTreeHashes_[ 242 ] = 0xb16129d9c3c9b419d2e6dc68cee386498dcde84c0047549322b1f08f2ae57ea4;
        emptyTreeHashes_[ 243 ] = 0x28fd198a2a5e173b9c4ffa110a11a50cde6f2bb1432625082bf9be1224fba75c;
        emptyTreeHashes_[ 244 ] = 0xd1ab6dd5d7e9f7cdeb7cf045e9bedb42820d97082ebe8953eb7168886959077d;
        emptyTreeHashes_[ 245 ] = 0xc345a1ddf732db106ca1e78e7d0fc7d41d6e674c99f3a8ab88dfe9c9ebeda19f;
        emptyTreeHashes_[ 246 ] = 0x53e96f44931cba77b5250d552f8044384ae19a88f75d80efd8963508d3f06dd6;
        emptyTreeHashes_[ 247 ] = 0x7bcd0928e4f3c1db66c2dbaa456bf46aacd892725a9bc4a1c8b87a594c693f18;
        emptyTreeHashes_[ 248 ] = 0xa595e686f1fb8123bf00b67d220b5853f8ce470d942387392b06f06a6749d0de;
        emptyTreeHashes_[ 249 ] = 0x61b34855bfdc9b8ec97bf582bd407e50cd6e1247cde484a4daacf29dcce8abba;
        emptyTreeHashes_[ 250 ] = 0xde70d6d799ae74d61c2282c904b790b4d8ea4ae9cfc6f8981e16a9874846e4ec;
        emptyTreeHashes_[ 251 ] = 0x32000514e1d34a85f7b732c6a0f16d27cc25ffb238de1c5c46326fde1a58e3a5;
        emptyTreeHashes_[ 252 ] = 0x6ff1a8f2e1ba2de7cc48ca8f6006a9401699a07032cc1168e2e7f06dd0d0fc22;
        emptyTreeHashes_[ 253 ] = 0x7f391690461b8e3468e2f6ba0fcba50df0195bd6d1bb187180650b00b2a13d5a;
        emptyTreeHashes_[ 254 ] = 0x6bbb316d292155ad8d2b47a03504033efbf70074141130e9e346a798f5904921;
        emptyTreeHashes_[ 255 ] = 0x395ebe57b2b0ca2592bc9b173eaaedf722c0121cf908386bf2b56d0179fde9c0;
    }

    /// @notice Calculates the root hash of the tree given a leaf and a proof
    function getRootHash(
        bytes32[] calldata proof,
        TreeEntry memory entry,
        address account
    ) public view returns (bytes32) {
        Blake2S.BLAKE2S_ctx memory ctx;
        uint256 keyHash = reverse(uint256(hashKey(ctx, account, entry.key)));

        uint256 emptyLen = TREE_DEPTH - proof.length;
        bytes32 result = hashLeaf(ctx, entry.leafIndex, entry.value);

        uint256 i = 0;
        for (; i < emptyLen; i++) {
            bytes32 adjacentHash = emptyTreeHashes_[i];
            if ((keyHash >> i) & 1 == 1) {
                result = hashBranch(ctx, adjacentHash, result);
            } else {
                result = hashBranch(ctx, result, adjacentHash);
            }
        }

        for (; i < TREE_DEPTH; i++) {
            bytes32 adjacentHash = proof[TREE_DEPTH - i - 1];
            if ((keyHash >> i) & 1 == 1) {
                result = hashBranch(ctx, adjacentHash, result);
            } else {
                result = hashBranch(ctx, result, adjacentHash);
            }
        }

        return result;
    }

    function hashBranch(bytes32 left, bytes32 right) public view returns (bytes32 result) {
        Blake2S.BLAKE2S_ctx memory ctx;
        return hashBranch(ctx, left, right);
    }
    
    function hashBranch(Blake2S.BLAKE2S_ctx memory ctx, bytes32 left, bytes32 right) internal view returns (bytes32 result) {
        uint256[2] memory DEFAULT_EMPTY_INPUT;
        Blake2S.init(
            ctx,
            32,
            "",
            DEFAULT_EMPTY_INPUT,
            DEFAULT_EMPTY_INPUT
        );
        Blake2S.update(ctx, abi.encodePacked(left, right));
        return Blake2S.finalize(ctx);
    }

    /// @notice Hashes the tree key
    function hashKey(Blake2S.BLAKE2S_ctx memory ctx, address account, uint256 key) internal view returns (bytes32) {
        bytes memory input = new bytes(64);
        assembly {
            // Store account starting at 12th byte
            mstore(add(input, 0x2c), shl(96, account)) 
            // Store key starting at 32th byte
            mstore(add(input, 0x40), key)
        }
        uint256[2] memory DEFAULT_EMPTY_INPUT;
        Blake2S.init(
            ctx,
            32,
            "",
            DEFAULT_EMPTY_INPUT,
            DEFAULT_EMPTY_INPUT
        );
        Blake2S.update(ctx, input);
        return Blake2S.finalize(ctx);
    }

    function hashLeaf(uint64 leafIndex, bytes32 value) public view returns (bytes32) {
        Blake2S.BLAKE2S_ctx memory ctx;
        return hashLeaf(ctx, leafIndex, value);
    }

    /// @notice Hashes an individual leaf
    function hashLeaf(Blake2S.BLAKE2S_ctx memory ctx, uint64 leafIndex, bytes32 value) internal view returns (bytes32) {
        bytes memory input = new bytes(40);
        assembly {
            // Store leafIndex at first 8 bytes
            mstore(add(input, 0x20), shl(192, leafIndex))
            // Store value at last 32 bytes
            mstore(add(input, 0x28), value)
        }
        uint256[2] memory DEFAULT_EMPTY_INPUT;
        Blake2S.init(
            ctx,
            32,
            "",
            DEFAULT_EMPTY_INPUT,
            DEFAULT_EMPTY_INPUT
        );
        Blake2S.update(ctx, input);
        return Blake2S.finalize(ctx);
    }

    /// @notice Returns the bit at the given bitOffset
    function bit(uint256 value, uint256 bitOffset) public view returns (bool) {
        return (value >> bitOffset) & 1 == 1;
    }

    /// @notice Reverses the bits of a 256-bit integer
    function reverse(uint256 input) public view returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }
}