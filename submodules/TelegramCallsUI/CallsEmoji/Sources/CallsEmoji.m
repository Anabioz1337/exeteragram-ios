#import <Foundation/Foundation.h>
#import <CallsEmoji/CallsEmoji.h>

#import <CommonCrypto/CommonCrypto.h>

static int32_t positionExtractor(uint8_t *bytes, int32_t i, int32_t count) {
    int offset = i * 8;
    int64_t num = (((int64_t)bytes[offset] & 0x7F) << 56) | (((int64_t)bytes[offset+1] & 0xFF) << 48) | (((int64_t)bytes[offset+2] & 0xFF) << 40) | (((int64_t)bytes[offset+3] & 0xFF) << 32) | (((int64_t)bytes[offset+4] & 0xFF) << 24) | (((int64_t)bytes[offset+5] & 0xFF) << 16) | (((int64_t)bytes[offset+6] & 0xFF) << 8) | (((int64_t)bytes[offset+7] & 0xFF));
    return num % count;
}

NSArray *emojisArray() {
    return @[ @"😉", @"😍", @"😛", @"😭", @"😱", @"😡", @"😎", @"😴", @"😵", @"😈", @"😬", @"😇", @"😏", @"👮", @"👷", @"💂", @"👶", @"👨", @"👩", @"👴", @"👵", @"😻", @"😽", @"🙀", @"👺", @"🙈", @"🙉", @"🙊", @"💀", @"👽", @"💩", @"🔥", @"💥", @"💤", @"👂", @"👀", @"👃", @"👅", @"👄", @"👍", @"👎", @"👌", @"👊", @"✌️", @"✋️", @"👐", @"👆", @"👇", @"👉", @"👈", @"🙏", @"👏", @"💪", @"🚶", @"🏃", @"💃", @"👫", @"👪", @"👬", @"👭", @"💅", @"🎩", @"👑", @"👒", @"👟", @"👞", @"👠", @"👕", @"👗", @"👖", @"👙", @"👜", @"👓", @"🎀", @"💄", @"💛", @"💙", @"💜", @"💚", @"💍", @"💎", @"🐶", @"🐺", @"🐱", @"🐭", @"🐹", @"🐰", @"🐸", @"🐯", @"🐨", @"🐻", @"🐷", @"🐮", @"🐗", @"🐴", @"🐑", @"🐘", @"🐼", @"🐧", @"🐥", @"🐔", @"🐍", @"🐢", @"🐛", @"🐝", @"🐜", @"🐞", @"🐌", @"🐙", @"🐚", @"🐟", @"🐬", @"🐋", @"🐐", @"🐊", @"🐫", @"🍀", @"🌹", @"🌻", @"🍁", @"🌾", @"🍄", @"🌵", @"🌴", @"🌳", @"🌞", @"🌚", @"🌙", @"🌎", @"🌋", @"⚡️", @"☔️", @"❄️", @"⛄️", @"🌀", @"🌈", @"🌊", @"🎓", @"🎆", @"🎃", @"👻", @"🎅", @"🎄", @"🎁", @"🎈", @"🔮", @"🎥", @"📷", @"💿", @"💻", @"☎️", @"📡", @"📺", @"📻", @"🔉", @"🔔", @"⏳", @"⏰", @"⌚️", @"🔒", @"🔑", @"🔎", @"💡", @"🔦", @"🔌", @"🔋", @"🚿", @"🚽", @"🔧", @"🔨", @"🚪", @"🚬", @"💣", @"🔫", @"🔪", @"💊", @"💉", @"💰", @"💵", @"💳", @"✉️", @"📫", @"📦", @"📅", @"📁", @"✂️", @"📌", @"📎", @"✒️", @"✏️", @"📐", @"📚", @"🔬", @"🔭", @"🎨", @"🎬", @"🎤", @"🎧", @"🎵", @"🎹", @"🎻", @"🎺", @"🎸", @"👾", @"🎮", @"🃏", @"🎲", @"🎯", @"🏈", @"🏀", @"⚽️", @"⚾️", @"🎾", @"🎱", @"🏉", @"🎳", @"🏁", @"🏇", @"🏆", @"🏊", @"🏄", @"☕️", @"🍼", @"🍺", @"🍷", @"🍴", @"🍕", @"🍔", @"🍟", @"🍗", @"🍱", @"🍚", @"🍜", @"🍡", @"🍳", @"🍞", @"🍩", @"🍦", @"🎂", @"🍰", @"🍪", @"🍫", @"🍭", @"🍯", @"🍎", @"🍏", @"🍊", @"🍋", @"🍒", @"🍇", @"🍉", @"🍓", @"🍑", @"🍌", @"🍐", @"🍍", @"🍆", @"🍅", @"🌽", @"🏡", @"🏥", @"🏦", @"⛪️", @"🏰", @"⛺️", @"🏭", @"🗻", @"🗽", @"🎠", @"🎡", @"⛲️", @"🎢", @"🚢", @"🚤", @"⚓️", @"🚀", @"✈️", @"🚁", @"🚂", @"🚋", @"🚎", @"🚌", @"🚙", @"🚗", @"🚕", @"🚛", @"🚨", @"🚔", @"🚒", @"🚑", @"🚲", @"🚠", @"🚜", @"🚦", @"⚠️", @"🚧", @"⛽️", @"🎰", @"🗿", @"🎪", @"🎭", @"🇯🇵", @"🇰🇷", @"🇩🇪", @"🇨🇳", @"🇺🇸", @"🇫🇷", @"🇪🇸", @"🇮🇹", @"🇷🇺", @"🇬🇧", @"1️⃣", @"2️⃣", @"3️⃣", @"4️⃣", @"5️⃣", @"6️⃣", @"7️⃣", @"8️⃣", @"9️⃣", @"0️⃣", @"🔟", @"❗️", @"❓", @"♥️", @"♦️", @"💯", @"🔗", @"🔱", @"🔴", @"🔵", @"🔶", @"🔷" ];
}

NSString *randomCallsEmoji() {
    NSArray *emojis = emojisArray();
    return emojis[arc4random() % emojis.count];
}

NSData *dataForEmojiRawKey(NSData *data) {
    if (!data) {
        return nil; // Return nil if the input data is nil
    }
    
    // Create a buffer to hold the hash
    uint8_t hash[CC_SHA256_DIGEST_LENGTH];
    
    // Compute the SHA-256 hash
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    // Return the hash as NSData
    return [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
}

NSArray<NSString *> *stringForEmojiHashOfData(NSData *data, NSInteger count) {
    if (data.length != 32) {
        return @[];
    }
    
    uint8_t bytes[32];
    [data getBytes:bytes length:32];
    
    NSArray *emojis = emojisArray();
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (int32_t i = 0; i < count; i++)
    {
        int32_t position = positionExtractor(bytes, i, (int32_t)emojis.count);
        NSString *emoji = emojis[position];
        [result addObject:emoji];
    }
    
    return result;
}
