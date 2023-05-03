#define CLOCK 2
#define READ_WRITE 3

const uint8_t ADDR[] = {46, 48, 50, 22, 46, 44, 42, 40, 38, 36, 34, 32, 30, 28, 26, 24};
const uint8_t DATA[] = {51, 49, 47, 45, 43, 41, 39, 37}; // MSB..LSB

void setup() {
  for (int i=0; i < 16; i++)
    pinMode(ADDR[i], INPUT);

  for (int i=0; i < 8; i++)
    pinMode(DATA[i], INPUT);

  pinMode(CLOCK, INPUT);
  pinMode(READ_WRITE, INPUT);

  attachInterrupt(digitalPinToInterrupt(CLOCK), onClock, RISING);

  Serial.begin(57600);
}

void onClock(){
  char hexOutput[15] = {0};

  /* output address */
  unsigned int address = 0;
  for (int i=0; i < 16; i++) {
    int bit = digitalRead(ADDR[i]) ? 1 : 0;
    address = (address << 1) + bit;
    Serial.print(bit);
  }

  Serial.print("\t");

  /* output corresponding data */
  unsigned int data = 0;
  for (int i=0; i < 8; i++) {
    int bit = digitalRead(DATA[i]) ? 1 : 0;
    data = (data << 1) + bit;
    Serial.print(bit);
  }

  sprintf(hexOutput, "   %04x  %c  %02x", address, digitalRead(READ_WRITE) ? 'r' : 'W' ,data);
  Serial.println(hexOutput);
}


void loop() { }
