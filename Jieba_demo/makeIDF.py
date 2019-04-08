import jieba
import jieba.analyse
import math
from utility import Utility as Ut
from configparser import ConfigParser

class IDF:
    def __init__(self, file_name: str = "extra/answerMap.cfg"):
        jieba.load_userdict("extra/myDict.dict")
        self.cfgParser = ConfigParser()
        self.cfgParser.read(file_name, encoding="UTF8")
        self.index = ['1', '2', '3', '4', '5', '6',
                      '7', '8', '9', '10', '11', '3',
                      '13', '14', '15', '16', '17', '18',
                      '19', '20', '21', '22', '23', '24',
                      '25', '26', '27', '28', '29', '30',
                      '30', '31', '32', '33', '34']

    def make_idf(self):
        all_dict = {}
        total = 0

        for i in self.index:
            cut_line = jieba.cut(self.cfgParser[i]['question'])
            stopwords = Ut.file2List("extra/myStop.txt")
            outstr = []
            for word in cut_line:
                if word not in stopwords:
                    if word != '\t' and word != '\n':
                        outstr.append(word)
            for word in outstr:
                if ' ' in outstr:
                    outstr.remove(' ')
            temp_dict = {}
            total += 1
            for word in outstr:
                # print(word)
                temp_dict[word] = 1
            for key in temp_dict:
                num = all_dict.get(key, 0)
                all_dict[key] = num + 1

            # print(temp_dict)
            # print(all_dict)
            # print(total)

        idf_dict={}
        for key in all_dict:
            # print(all_dict[key])
            w = key
            p = '%.10f' % (math.log10(total / (all_dict[key] + 1)))
            if w > u'\u4e00' and w <= u'\u9fa5':
                idf_dict[w] = p
        print('IDF字典构造结束')
        fw_idf = open('extra/myIDF.txt', 'w', encoding='utf-8')
        fw_word = open('extra/myWordsLib.txt', 'w', encoding='utf-8')

        for k in idf_dict:
            if k != '\n':
                fw_idf.write(k + ' ' + idf_dict[k] + '\n')
                fw_word.write(k + '\n')
        fw_idf.close()
        fw_word.close()




