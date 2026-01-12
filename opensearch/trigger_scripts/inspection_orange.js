// Inspection Process - Orange Trigger (7-9점)
// 조건: 총점이 7점 이상 10점 미만

if (ctx.results[0].hits.total.value == 0) {
    return false;
}

for (def hit : ctx.results[0].hits.hits) {
    def source = hit._source;
    def sensors = source.sensors;

    def weig = 0.0;
    def torq = 0.0;

    for (def item : sensors) {
        if (item.type == "weig") { weig = item.value; }
        if (item.type == "torq") { torq = item.value; }
    }

    // 점수 계산
    int score_weig = 1;
    int score_torq = 1;
    int score_phot = 1;

    // Weight scoring
    if (weig < ${weight_red_low} || weig > ${weight_red_high}) {
        score_weig = 10;
    }
    else if ((weig >= ${weight_yellow_low} && weig <= 999) || (weig >= 1101 && weig <= ${weight_yellow_high})) {
        score_weig = 3;
    }

    // Torque scoring
    if (torq < ${torque_red_low} || torq > ${torque_red_high}) {
        score_torq = 10;
    }
    else if (torq >= ${torque_orange_low} && torq <= ${torque_orange_high}) {
        score_torq = 4;
    }
    else if (torq >= ${torque_yellow_low} && torq <= ${torque_yellow_high}) {
        score_torq = 2;
    }

    int total_score = score_weig + score_torq + score_phot;

    if (total_score >= ${orange_min} && total_score < ${orange_max}) {
        return true;
    }
}

return false;
