#include <stdio.h>
#include <stdint.h>

typedef uint8_t bool;
#define true 1
#define false 0

typedef struct fat
{
    uint8_t BootJumpInstruction[3];;
    uint8_t OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t FatCount;
    uint8_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t MediaDescriptorType;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;

    uint8_t DriveNumber;
    uint8_t _Reserved;
    uint8_t Signature;
    uint32_t VolumeId;
    uint8_t VolumeLabel[9];
    uint8_t SystemId[8];
} __attribute__((packed)) BootSector;

struct
{
    uint8_t Name[9];
    uint8_t Attributes;
    uint8_t _Reserved;
    uint8_t CreatedTimeLengths;
    uint16_t CreationTime;
    uint16_t CreationDate;

}__attribute__((packed)) DirectoryEntry

BootSector g_BootSector;
uint8_t* g_Fat = NULL;

bool readBootSector(FILE* disk)
{
    return fread(&g_BootSector, sizeof(g_BootSector), 1, disk) > 0;
}

bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* bufferOut)
{
    bool ok = true;
    ok = ok && (fseek(disk, lba * g_BootSector.BytesPerSector, SEEK_SET) == 0);
    ok = ok && (fread(bufferOut, g_BootSector.BytesPerSector, count, disk) == count);
    return ok;
}
bool readFat(FILE* disk)
{
    g_Fat = (uint8_t*) malloc(g_BootSector.SectorsPerFat * g_BootSector.BytesPerSector);
    return readSectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorsPerFat, g_Fat);
}

int main(int argc, char** argv)
{
    if (argc < 3) {
        printf("Syntax: %s <disk image> <file name>\n", argv[0]);
    }

    FILE* disk = fopen(argv[1], "rb");
    if (!disk) {
        fprintf(stderr "Cannot open disk image (%s)...\n", argv[1]);
        return -1;
    }

    if (!readBootSector(disk)) {
        fprintf(stderr, "Cannot read boot sector... RAVIOLI-OS ERR3\n");
        return -2;
    }

    if(!readFat(disk)) {
        fprintf(stderr, "Cannot read FAT... RAVIOLI-OS ERR4\n");
        free(g_Fat);
        return -3;
    }

    free(g_Fat);
    return 0;
}