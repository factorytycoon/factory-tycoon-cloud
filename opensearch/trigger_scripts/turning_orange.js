// Turning Process - Orange Trigger (7-9점)
// 조건: 총점이 7점 이상 10점 미만

if (ctx.results[0].hits.total.value == 0) {
    return false;
}

for (def hit : ctx.results[0].hits.hits) {
    def source = hit._source;
    def sensors = source.sensors;

    def rpm = 0.0;
    def nois = 0.0;
    def disp = 0.0;

    for (def item : sensors) {
        if (item.type == "rpm") { rpm = item.value; }
        if (item.type == "nois") { nois = item.value; }
        if (item.type == "disp") { disp = item.value; }
    }

    // 점수 계산
    int score_rpm = 1;
    int score_nois = 1;
    int score_disp = 1;

    // RPM scoring
    if (rpm < ${rpm_red_low}) {
        score_rpm = 10;
    }
    else if ((rpm >= ${rpm_orange_low} && rpm <= ${rpm_orange_high}) || rpm > ${rpm_orange_high2}) {
        score_rpm = 3;
    }
    else if (rpm >= ${rpm_yellow_low} && rpm <= ${rpm_yellow_high}) {
        score_rpm = 2;
    }

    // Noise scoring
    if (nois > ${noise_red}) {
        score_nois = 10;
    }
    else if (nois >= ${noise_orange_low} && nois <= ${noise_orange_high}) {
        score_nois = 3;
    }
    else if (nois >= ${noise_yellow_low} && nois <= ${noise_yellow_high}) {
        score_nois = 2;
    }

    // Displacement scoring
    if (disp > ${displacement_red}) {
        score_disp = 10;
    }
    else if (disp >= ${displacement_orange_low} && disp <= ${displacement_orange_high}) {
        score_disp = 3;
    }
    else if (disp >= ${displacement_yellow_low} && disp <= ${displacement_yellow_high}) {
        score_disp = 2;
    }

    int total_score = score_rpm + score_nois + score_disp;

    if (total_score >= 7 && total_score < 10) {
        return true;
    }
}

return false;
