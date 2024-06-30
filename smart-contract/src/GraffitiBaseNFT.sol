pragma solidity 0.8.21;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import {ColorAlreadyUsed, NeedHigherEthValue} from "./errors.sol";

import {BMPImage} from "./BMPEncoder.sol";

//const number of lines
uint256 constant LINES = 64;

contract GraffitiBaseNFT is ERC721Upgradeable, OwnableUpgradeable {
    using Strings for uint256;
    using Strings for address;

    event FloorPriceChanged(uint256 newPrice);

    struct GraffitiBase {
        uint256 id;
        uint32 color;
        address creator;
        address owner;
        address colorOwner;
        uint256[] graffiti;
    }

    /// @custom:storage-location erc7201:gb.0
    struct StorageV0 {
        BMPImage renderer;
        uint256 totalSupply;
        mapping(uint256 => uint256) usedColor;
        mapping(uint256 => uint256[LINES + 1]) graffitybases;
        uint256 floorPrice;
    }


    function _getStorageV0() private pure returns (StorageV0 storage $) {
        assembly {
            $.slot := STORAGE_V0_LOCATION
        }
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC721StorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;
    // keccak256(abi.encode(uint256(keccak256("gb.0")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_V0_LOCATION = 0x5e03c951e7b713004beca51c0e620ca0c95e9161aa840a068b05fb9c65653800;

    function getStorage() public view returns (BMPImage renderer) {
        StorageV0 storage $ = _getStorageV0();
        return ($.renderer);
    }

    function setDependencies(address renderer) public onlyOwner {
        StorageV0 storage $ = _getStorageV0();
        $.renderer = BMPImage(renderer);
    }

    function initialize(address renderer, address owner) initializer public {
		__ERC721_init_unchained("GraffitiBase", "GB");
		__Ownable_init_unchained(owner);
        StorageV0 storage $ = _getStorageV0();
		$.renderer = BMPImage(renderer);
	}

    constructor() {
        _disableInitializers();
    }

    function totalSupply() public view returns (uint256) {
        return _getStorageV0().totalSupply;
    }

    function pricingfunc(uint256 time) public pure returns (uint256) {
        // TODO time bond, this will revert after Sun Jul 14 2024 12:32:46 GMT+0000
        // deactivating the force buying, should be updated to another mechanism
        return (1720960366 - time) * 1_000_000_000;
    }

    function getMinFloorPrice() public view returns (uint256) {
        StorageV0 storage $ = _getStorageV0();
        return $.floorPrice + pricingfunc(block.timestamp);
    }

    function getGraffitiBase(uint256 tokenId) public view returns (GraffitiBase memory) {
        uint256[] memory dynArray = new uint256[](LINES);
        StorageV0 storage $ = _getStorageV0();
        uint256 extraData = $.graffitybases[tokenId][LINES];
        for (uint256 i = 0; i < LINES; i++) {
            dynArray[i] = $.graffitybases[tokenId][i];
        }
        GraffitiBase memory ret = GraffitiBase(
            tokenId,
            uint32(extraData & 0xffffff),
            address(uint160((extraData) >> 24)),
            ownerOf(tokenId),
            address(uint160($.usedColor[extraData & 0xffffff] & ~((~0x00 >> 160) << 160))),
            dynArray
        );
        return ret;
    }

    function mintGraffitiBaseOf(uint256[LINES] calldata sig, uint256 color, address to) public {
        _doMint(to, color);
        _updateGraffitiBaseTo(to, _getStorageV0().totalSupply - 1, sig, color);
    }

    function _doMint(address to, uint256 color) internal {
        StorageV0 storage $ = _getStorageV0();
		if ($.usedColor[color] != 0) revert ColorAlreadyUsed();

        uint256 totalSupply_ = $.totalSupply + 1;
        _safeMint(to, totalSupply_ - 1);
        $.usedColor[color] = (uint256(uint160(to)) | (totalSupply_ - 1) << 160);
        $.totalSupply = totalSupply_;
    }

    function _updateGraffitiBaseTo(address to, uint256 tokenId, uint256[LINES] calldata sig, uint256 color) internal {
        StorageV0 storage $ = _getStorageV0();
        if ((color & 0xffffff) == 0x000000) revert ColorAlreadyUsed();
        // Setting `to` in stone
        uint256 extraData = (color & uint256(0xffffff));
        extraData =
            (extraData & (~uint256(0xffffffffffffffffffffffffffffffffffffffff000000))) | (uint256(uint160(to)) << 24); // Blankaddress slot
        extraData =
            (extraData & (~uint256(0x0000000000000000000000000000000000000000000000))) | (uint256(uint160(to)) << 24); // Set address

        uint256[LINES + 1] memory newparts;
        for (uint256 i = 0; i < LINES; i++) {
            newparts[i] = sig[i];
        }
        newparts[LINES] = extraData;
        $.graffitybases[tokenId] = newparts;
    }

    function metadata(uint256 id) internal view returns (string memory) {
        return _metadata(getGraffitiBase(id));
    }

    function _metadata(GraffitiBase memory gb) public view returns (string memory) {
        StorageV0 storage $ = _getStorageV0();
        string memory desc;
        //adding wall text mentionning the minter, the used color, the block number and birth date
        desc = string(abi.encodePacked("Graffiti ", gb.id.toString()));

        if (gb.id % 2 == 0) desc = string(abi.encodePacked(desc, unicode"º"));
        else desc = string(abi.encodePacked(desc, unicode"ª"));

        desc = string(abi.encodePacked(desc, unicode" \\n\\n", " - Color: ", uint256(gb.color).toHexString()));
		// TODO all NFT caracteristics
        return string(
            abi.encodePacked(
                '{"name":"',
                name(),
                '", "description":"',
                desc,
                '", "attributes": [',
                addRGBTraits(gb.color),
                "], ",
                abi.encodePacked('"external_url": "https://6120.eu/posts/graffiti-base?gb=', gb.id.toString()),
                '", "image":"',
                $.renderer.B64MimeEncode("image/bmp", BMP_(gb)),
                '"}'
            )
        );
    }

    function addRGBTraits(uint256 color) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                addIntTrait("Red", ((color & 0xFF0000) >> 16)),
                ", ",
                addIntTrait("Green", ((color & 0x00FF00) >> 8)),
                ", ",
                addIntTrait("Blue", ((color & 0x0000FF)))
            )
        );
    }

    function addDateTraits(uint256 y, uint256 m, uint256 d) internal pure returns (string memory) {
        return
            string(abi.encodePacked(addIntTrait("Year", y), ", ", addIntTrait("Month", m), ", ", addIntTrait("Day", d)));
    }

    function addIntTrait(string memory key, uint256 value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"', key, '": ', value.toString(), "}"));
    }

    function addAddressTrait(string memory key, address value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"', key, '": "', value.toHexString(), '"}'));
    }

    function addBoolTrait(string memory key, bool value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"', key, '": ', (value ? "true" : "false"), "}"));
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return _getStorageV0().renderer.B64MimeEncode("application/json", bytes(metadata(id)));
    }

    function convertArray(uint256[LINES + 1] storage arr) internal view returns (uint256[] memory, uint256) {
        uint256[] memory convertedArr = new uint256[](LINES);
        for (uint256 i = 0; i < LINES; i++) {
            convertedArr[i] = arr[i];
        }
        return (convertedArr, arr[LINES]);
    }

    function BMP(uint256 tokenId) public view returns (bytes memory) {
        return BMP_(getGraffitiBase(tokenId));
    }

    function BMP_(GraffitiBase memory gb) public view returns (bytes memory) {
        StorageV0 storage $ = _getStorageV0();
        BMPImage renderer = $.renderer;
        BMPImage.Image memory img = renderer.newImage(130, 130);
        img = renderer.draw128pxLinesBitfield(img, 1, 1, gb.color, gb.graffiti);

        return renderer.encode(img);
    }

    function obtainNFT(uint256 tokenId) public payable {
        StorageV0 storage $ = _getStorageV0();
        if (msg.value < getMinFloorPrice()) revert NeedHigherEthValue();
        $.floorPrice = msg.value;
        _transfer(ownerOf(tokenId), msg.sender, tokenId);
        emit FloorPriceChanged(msg.value);
    }
}
