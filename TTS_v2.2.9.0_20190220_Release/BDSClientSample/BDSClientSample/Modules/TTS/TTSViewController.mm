//
//  ViewController.m
//  TTSDemo
//
//  Created by lappi on 3/8/16.
//  Copyright © 2016 baidu. All rights reserved.
//

#import "TTSViewController.h"
#import "BDSSpeechSynthesizer.h"
#import "TTDFileReader.h"
#import "TTSConfigViewController.h"
#import <AVFoundation/AVFoundation.h>

#define READ_SYNTHESIS_TEXT_FROM_FILE (NO)
static BOOL isSpeak = YES;
static BOOL textFromFile = READ_SYNTHESIS_TEXT_FROM_FILE;
static BOOL displayAllSentences = !READ_SYNTHESIS_TEXT_FROM_FILE;

//#error 请在官网新建app，配置bundleId，并在此填写相关参数
NSString* APP_ID = @"15792399";
NSString* API_KEY = @"GDLte8m46gR1wgvElaSypLKT";
NSString* SECRET_KEY = @"241dglejdbf6GnnfedBn55wEvpqya8HW";

@interface TTSViewController ()
@property (nonatomic,strong)NSMutableArray* synthesisTexts;
@property (nonatomic,strong)NSMutableArray* addTextQueue; /*used with textFromFile*/
@end

@implementation TTSViewController

+ (BOOL)isFileSynthesisEnabled{
    return textFromFile;
}
+ (BOOL)isSpeakEnabled{
    return isSpeak;
}
+ (void)setFileSynthesisEnabled:(BOOL)isEnabled{
    textFromFile = isEnabled;
    displayAllSentences = !textFromFile;
}
+ (void)setSpeakEnabled:(BOOL)isEnabled{
    isSpeak = isEnabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.SynthesizeTextInputView setBackgroundColor:[UIColor colorWithRed:0.9 green:1 blue:0.9 alpha:1]];
    [self.SynthesizeTextProgressView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
    [self.SynthesizeTextInputView setDelegate:self];
    [self.PauseOrResumeButton setEnabled:NO];
    [self.CancelButton setEnabled:NO];
    self.synthesisTexts = [[NSMutableArray alloc] init];
    [self configureSDK];
    
    [self.SynthesizeTextInputView setText:@"这个世界很复杂，百度AI更懂你"];
}


-(void)viewWillAppear:(BOOL)animated{
    if(textFromFile || self.SynthesizeTextInputView.text.length > 0){
        [self.SynthesizeButton setEnabled:YES];
        self.addTextQueue = [[NSMutableArray alloc] init];
    }
    else{
        [self.SynthesizeButton setEnabled:NO];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)configureSDK{
    NSLog(@"TTS version info: %@", [BDSSpeechSynthesizer version]);
    [BDSSpeechSynthesizer setLogLevel:BDS_PUBLIC_LOG_VERBOSE];
    [[BDSSpeechSynthesizer sharedInstance] setSynthesizerDelegate:self];
    [self configureOnlineTTS];
    [self configureOfflineTTS];
    
}

-(void)displayError:(NSError*)error withTitle:(NSString*)title{
    NSString* errMessage = error.localizedDescription;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:errMessage preferredStyle:UIAlertControllerStyleAlert];
    if(alert){
        UIAlertAction* dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {}];
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        UIAlertView *alertv = [[UIAlertView alloc] initWithTitle:title message:errMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        if(alertv){
            [alertv show];
        }
    }
}

-(void)configureOnlineTTS{
    
    [[BDSSpeechSynthesizer sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(BDS_SYNTHESIZER_SPEAKER_FEMALE) forKey:BDS_SYNTHESIZER_PARAM_SPEAKER];
    //    [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(10) forKey:BDS_SYNTHESIZER_PARAM_ONLINE_REQUEST_TIMEOUT];
    
}

-(void)configureOfflineTTS{
    
    NSError *err = nil;
    // 在这里选择不同的离线音库（请在XCode中Add相应的资源文件），同一时间只能load一个离线音库。根据网络状况和配置，SDK可能会自动切换到离线合成。
    NSString* offlineEngineSpeechData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Speech_Female" ofType:@"dat"];
    
    NSString* offlineChineseAndEnglishTextData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Text" ofType:@"dat"];
    
    err = [[BDSSpeechSynthesizer sharedInstance] loadOfflineEngine:offlineChineseAndEnglishTextData speechDataPath:offlineEngineSpeechData licenseFilePath:nil withAppCode:APP_ID];
    if(err){
        [self displayError:err withTitle:@"Offline TTS init failed"];
        return;
    }
    [TTSConfigViewController loadedAudioModelWithName:@"Chinese female" forLanguage:@"chn"];
    [TTSConfigViewController loadedAudioModelWithName:@"English female" forLanguage:@"eng"];
}

-(void)updateSynthProgress{
    [self.SynthesizeTextProgressView setText:nil];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
    if(displayAllSentences){
        for(NSDictionary* contentDict in self.synthesisTexts){
            [str appendAttributedString:[contentDict objectForKey:@"TEXT"]];
        }
    }
    else{
        if(self.synthesisTexts.count > 0){
            NSDictionary* contentDict = [self.synthesisTexts objectAtIndex:0];
            [str appendAttributedString:[contentDict objectForKey:@"TEXT"]];
        }
    }
    [self.SynthesizeTextProgressView setAttributedText:str];
}

-(void)addFileTextLoop
{
    if(self.addTextQueue.count > 0){
        NSAttributedString* string = [[NSAttributedString alloc] initWithString:[self.addTextQueue objectAtIndex:0]];
        [self.addTextQueue removeObjectAtIndex:0];
        NSInteger sentenceID;
        NSError* err = nil;
        if(isSpeak)
            sentenceID = [[BDSSpeechSynthesizer sharedInstance] speakSentence:[string string] withError:&err];
        else
            sentenceID = [[BDSSpeechSynthesizer sharedInstance] synthesizeSentence:[string string] withError:&err];
        if(err == nil){
            NSMutableDictionary *addedString = [[NSMutableDictionary alloc] initWithObjects:@[string, [NSNumber numberWithInteger:sentenceID], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0]] forKeys:@[@"TEXT", @"ID", @"SPEAK_LEN", @"SYNTH_LEN"]];
            [self.synthesisTexts addObject:addedString];
            [self updateSynthProgress];
            if(self.synthesisTexts.count == 1){
                [self.CancelButton setEnabled:YES];
                [self.PauseOrResumeButton setEnabled:YES];
            }
        }
        else{
            [self displayError:err withTitle:@"Add sentence Error"];
            [self.addTextQueue removeAllObjects];
        }
    }
    if(self.addTextQueue.count > 0){
        [self performSelector:@selector(addFileTextLoop) withObject:nil afterDelay:0.2];
    }
}

- (IBAction)SynthesizeTapped:(id)sender {
    if(textFromFile){
        NSString * text_file =[[NSBundle mainBundle] pathForResource:@"tts_text" ofType:@"txt"];
        if(text_file == nil){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"File not found" message:@"Couldn't find test text file \"tts_text.txt\" from mainBundle" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {}];
            [alert addAction:dismiss];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        int total = 0;
        TTDFileReader* reader = [[TTDFileReader alloc] initWithFilePath:text_file];
        
        NSString *line = @"";
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8/*kCFStringEncodingGB_18030_2000*/);
        while ( (line = [reader readLineWithEncoding:encoding]) ) {
            total++;
        }
        int added = 1;
        reader = [[TTDFileReader alloc] initWithFilePath:text_file];
        
        while ( (line = [reader readLineWithEncoding:encoding]) ) {
            [self.addTextQueue addObject:[NSString stringWithFormat:@"Text %d of %d: %@", added, total, line]];
            added++;
        }
        //        }
        [self performSelector:@selector(addFileTextLoop) withObject:nil afterDelay:0.2];
    }
    else{
        [self.SynthesizeButton setEnabled:NO];
        NSAttributedString* string = [[NSAttributedString alloc] initWithString:self.SynthesizeTextInputView.text];
        [self.SynthesizeTextInputView setText:nil];
        NSInteger sentenceID;
        NSError* err = nil;
        if(isSpeak)
            sentenceID = [[BDSSpeechSynthesizer sharedInstance] speakSentence:[string string] withError:&err];
        else
            sentenceID = [[BDSSpeechSynthesizer sharedInstance] synthesizeSentence:[string string] withError:&err];
        if(err == nil){
            NSMutableDictionary *addedString = [[NSMutableDictionary alloc] initWithObjects:@[string, [NSNumber numberWithInteger:sentenceID], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0]] forKeys:@[@"TEXT", @"ID", @"SPEAK_LEN", @"SYNTH_LEN"]];
            [self.synthesisTexts addObject:addedString];
            [self updateSynthProgress];
            if(self.synthesisTexts.count == 1){
                [self.CancelButton setEnabled:YES];
                [self.PauseOrResumeButton setEnabled:YES];
            }
        }
        else{
            [self displayError:err withTitle:@"Add sentence Error"];
        }
    }
}

- (IBAction)PauseOrResumeTapped:(id)sender {
    if([[BDSSpeechSynthesizer sharedInstance] synthesizerStatus] == BDS_SYNTHESIZER_STATUS_PAUSED){
        [[BDSSpeechSynthesizer sharedInstance] resume];
    }else if([[BDSSpeechSynthesizer sharedInstance] synthesizerStatus] == BDS_SYNTHESIZER_STATUS_WORKING){
        [[BDSSpeechSynthesizer sharedInstance] pause];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Synthesis doesn't seem to be running so can't pause or resume..." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {}];
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
        [self.CancelButton setEnabled:NO];
        [self.PauseOrResumeButton setEnabled:NO];
    }
}
- (IBAction)CancelTapped:(id)sender {
    if(self.addTextQueue){
        [self.addTextQueue removeAllObjects];
    }
    [[BDSSpeechSynthesizer sharedInstance] cancel];
    [self.synthesisTexts removeAllObjects];
    [self updateSynthProgress];
    [self.CancelButton setEnabled:NO];
    [self.PauseOrResumeButton setEnabled:NO];
    [self.PauseOrResumeButton setTitle:[[NSBundle mainBundle] localizedStringForKey:@"pause" value:@"" table:@"Localizable"] forState:UIControlStateNormal];
}

- (IBAction)DismissKeyboard:(id)sender {
    [self.SynthesizeTextInputView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.text.length > 0){
        [self.SynthesizeButton setEnabled:YES];
    }
    else{
        [self.SynthesizeButton setEnabled:NO];
    }
}

- (NSAttributedString *)string:(NSString *)string withColor:(UIColor *)color
{
    NSMutableAttributedString *colorfulString = [[NSMutableAttributedString alloc] initWithString:string];
    [colorfulString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [colorfulString length])];
    [colorfulString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:14.0] range:NSMakeRange(0, [colorfulString length])];
    return colorfulString;
}

-(void)refreshAfterProgressUpdate:(NSMutableDictionary*)updatedSentence{
    NSString* totalText = [((NSAttributedString*)[updatedSentence objectForKey:@"TEXT"]) string];
    NSInteger readOffset = [[updatedSentence objectForKey:@"SPEAK_LEN"] integerValue];
    NSInteger synthOffset = [[updatedSentence objectForKey:@"SYNTH_LEN"] integerValue];
    
    NSLog(@"UPDATE PROGRESS: ReadLen: %ld, SynthLen: %ld, TotalLen: %ld", readOffset, synthOffset, totalText.length);
    
    NSRange readRange = NSMakeRange(0, readOffset);
    NSRange synthRange = NSMakeRange(readOffset, synthOffset-readOffset);
    NSRange unprocessedRange = NSMakeRange(synthOffset, totalText.length-synthOffset);
    
    NSString* readText = [totalText substringWithRange: readRange];
    NSString* synthesizeSentenceText = [totalText substringWithRange: synthRange];
    NSString* unProcessedText = [totalText substringWithRange: unprocessedRange];
    
    NSMutableAttributedString *allMessage = [[NSMutableAttributedString alloc] initWithAttributedString:[self string: readText withColor: [UIColor redColor]]];
    [allMessage appendAttributedString:[self string: synthesizeSentenceText withColor: [UIColor blueColor]]];
    [allMessage appendAttributedString:[self string: unProcessedText withColor: [UIColor blackColor]]];
    [updatedSentence setObject:allMessage forKey:@"TEXT"];
    [self updateSynthProgress];
}

#pragma mark - implement BDSSpeechSynthesizerDelegate
- (void)synthesizerStartWorkingSentence:(NSInteger)SynthesizeSentence{
    NSLog(@"Did start synth %ld", SynthesizeSentence);
    [self.CancelButton setEnabled:YES];
    [self.PauseOrResumeButton setEnabled:YES];
}

- (void)synthesizerFinishWorkingSentence:(NSInteger)SynthesizeSentence{
    NSLog(@"Did finish synth, %ld", SynthesizeSentence);
    if(!isSpeak){
        if(self.synthesisTexts.count > 0 &&
           SynthesizeSentence == [[[self.synthesisTexts objectAtIndex:0] objectForKey:@"ID"] integerValue]){
            [self.synthesisTexts removeObjectAtIndex:0];
            [self updateSynthProgress];
        }
        else{
            NSLog(@"Sentence ID mismatch??? received ID: %ld\nKnown sentences:", (long)SynthesizeSentence);
            for(NSDictionary* dict in self.synthesisTexts){
                NSLog(@"ID: %ld Text:\"%@\"", [[dict objectForKey:@"ID"] integerValue], [((NSAttributedString*)[dict objectForKey:@"TEXT"]) string]);
            }
        }
        if(self.synthesisTexts.count == 0){
            [self.CancelButton setEnabled:NO];
            [self.PauseOrResumeButton setEnabled:NO];
            [self.PauseOrResumeButton setTitle:[[NSBundle mainBundle] localizedStringForKey:@"pause" value:@"" table:@"Localizable"] forState:UIControlStateNormal];
        }
    }
}

- (void)synthesizerSpeechStartSentence:(NSInteger)SpeakSentence{
    NSLog(@"Did start speak %ld", SpeakSentence);
}

- (void)synthesizerSpeechEndSentence:(NSInteger)SpeakSentence{
    NSLog(@"Did end speak %ld", SpeakSentence);
    if(self.synthesisTexts.count > 0 &&
       SpeakSentence == [[[self.synthesisTexts objectAtIndex:0] objectForKey:@"ID"] integerValue]){
        [self.synthesisTexts removeObjectAtIndex:0];
        [self updateSynthProgress];
    }
    else{
        NSLog(@"Sentence ID mismatch??? received ID: %ld\nKnown sentences:", (long)SpeakSentence);
        for(NSDictionary* dict in self.synthesisTexts){
            NSLog(@"ID: %ld Text:\"%@\"", [[dict objectForKey:@"ID"] integerValue], [((NSAttributedString*)[dict objectForKey:@"TEXT"]) string]);
        }
    }
    if(self.synthesisTexts.count == 0){
        [self.CancelButton setEnabled:NO];
        [self.PauseOrResumeButton setEnabled:NO];
        [self.PauseOrResumeButton setTitle:[[NSBundle mainBundle] localizedStringForKey:@"pause" value:@"" table:@"Localizable"] forState:UIControlStateNormal];
    }
}

- (void)synthesizerNewDataArrived:(NSData *)newData
                       DataFormat:(BDSAudioFormat)fmt
                   characterCount:(int)newLength
                   sentenceNumber:(NSInteger)SynthesizeSentence{
    NSMutableDictionary* sentenceDict = nil;
    for(NSMutableDictionary *dict in self.synthesisTexts){
        if([[dict objectForKey:@"ID"] integerValue] == SynthesizeSentence){
            sentenceDict = dict;
            break;
        }
    }
    if(sentenceDict == nil){
        NSLog(@"Sentence ID mismatch??? received ID: %ld\nKnown sentences:", (long)SynthesizeSentence);
        for(NSDictionary* dict in self.synthesisTexts){
            NSLog(@"ID: %ld Text:\"%@\"", [[dict objectForKey:@"ID"] integerValue], [((NSAttributedString*)[dict objectForKey:@"TEXT"]) string]);
        }
        return;
    }
    [sentenceDict setObject:[NSNumber numberWithInteger:newLength] forKey:@"SYNTH_LEN"];
    [self refreshAfterProgressUpdate:sentenceDict];
}

- (void)synthesizerTextSpeakLengthChanged:(int)newLength
                           sentenceNumber:(NSInteger)SpeakSentence{
    NSLog(@"SpeakLen %ld, %d", SpeakSentence, newLength);
    NSMutableDictionary* sentenceDict = nil;
    for(NSMutableDictionary *dict in self.synthesisTexts){
        if([[dict objectForKey:@"ID"] integerValue] == SpeakSentence){
            sentenceDict = dict;
            break;
        }
    }
    if(sentenceDict == nil){
        NSLog(@"Sentence ID mismatch??? received ID: %ld\nKnown sentences:", (long)SpeakSentence);
        for(NSDictionary* dict in self.synthesisTexts){
            NSLog(@"ID: %ld Text:\"%@\"", [[dict objectForKey:@"ID"] integerValue], [((NSAttributedString*)[dict objectForKey:@"TEXT"]) string]);
        }
        return;
    }
    [sentenceDict setObject:[NSNumber numberWithInteger:newLength] forKey:@"SPEAK_LEN"];
    [self refreshAfterProgressUpdate:sentenceDict];
}

- (void)synthesizerdidPause{
    [self.PauseOrResumeButton setTitle:[[NSBundle mainBundle] localizedStringForKey:@"resume" value:@"" table:@"Localizable"] forState:UIControlStateNormal];
}

- (void)synthesizerResumed{
    NSLog(@"Did resume");
    [self.PauseOrResumeButton setTitle:[[NSBundle mainBundle] localizedStringForKey:@"pause" value:@"" table:@"Localizable"] forState:UIControlStateNormal];
}

- (void)synthesizerCanceled{
    NSLog(@"Did cancel");
}

- (void)synthesizerErrorOccurred:(NSError *)error
                        speaking:(NSInteger)SpeakSentence
                    synthesizing:(NSInteger)SynthesizeSentence{
    NSLog(@"Did error %ld, %ld", SpeakSentence, SynthesizeSentence);
    if(self.addTextQueue){
        [self.addTextQueue removeAllObjects];
    }
    [self.PauseOrResumeButton setTitle:[[NSBundle mainBundle] localizedStringForKey:@"pause" value:@"" table:@"Localizable"] forState:UIControlStateNormal];
    [self.CancelButton setEnabled:NO];
    [self.PauseOrResumeButton setEnabled:NO];
    [self.synthesisTexts removeAllObjects];
    [self updateSynthProgress];
    [[BDSSpeechSynthesizer sharedInstance] cancel];
    [self displayError:error withTitle:@"Synthesis failed"];
}

- (IBAction)DismissTTS:(id)sender {
    [self CancelTapped:self];
    [BDSSpeechSynthesizer releaseInstance];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
@end

