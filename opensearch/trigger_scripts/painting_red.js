// Painting Process - Red Trigger (≥10점)
// 조건: 총점이 10점 이상

if (ctx.results[0].hits.total.value == 0) {
    return false;
}

for (def hit : ctx.results[0].hits.hits) {
    def source = hit._source;
    def sensors = source.sensors;

    def pres = 0.0;
    def voc = 0.0;
    def temp = 0.0;

    for (def item : sensors) {
        if (item.type == "pres") { pres = item.value; }
        if (item.type == "voc") { voc = item.value; }
        if (item.type == "temp") { temp = item.value; }
    }

    // 점수 계산
    int score_pres = 1;
    int score_voc = 1;
    int score_temp = 1;

    // VOC scoring
    if (voc > ${voc_red}) {
        score_voc = 10;
    }
    else if (voc >= ${voc_orange_low} && voc <= ${voc_orange_high}) {
        score_voc = 6;
    }
    else if (voc >= ${voc_yellow_low} && voc <= ${voc_yellow_high}) {
        score_voc = 3;
    }

    // Pressure scoring
    if (pres < ${pressure_red_low} || pres > ${pressure_red_high}) {
        score_pres = 10;
    }
    else if ((pres >= ${pressure_orange_low} && pres <= 3.7) || (pres >= 4.3 && pres <= ${pressure_orange_high})) {
        score_pres = 3;
    }
    else if ((pres >= ${pressure_yellow_low} && pres <= 3.7) || (pres >= 4.3 && pres <= ${pressure_yellow_high})) {
        score_pres = 2;
    }

    // Temperature scoring
    if (temp > ${temp_red}) {
        score_temp = 10;
    }
    else if ((temp >= ${temp_orange_low} && temp <= 41) || (temp >= 49 && temp <= ${temp_orange_high})) {
        score_temp = 3;
    }
    else if ((temp >= ${temp_yellow_low} && temp <= 41) || (temp >= 49 && temp <= ${temp_yellow_high})) {
        score_temp = 2;
    }

    int total_score = score_pres + score_voc + score_temp;

    if (total_score >= 10) {
        return true;
    }
}

return false;
